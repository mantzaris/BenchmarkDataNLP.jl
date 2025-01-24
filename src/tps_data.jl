


using JSON
using Random
using StatsBase


const alphabet_unicode_start_ind = 44032 #0xAC00 HANGUL_START = 0xAC00
const min_alphabet_size = 5
const alphabet_size_complexity_100 = 50

const min_word_size = 5
const word_size_complexity_100 = 20

const min_vocabulary_size = 10
const vocabulary_size_complexity_100 = 10_000

const min_bridgeword_count = 3
const bridgeword_count_complexity_100 = 300



struct TextTemplate
    text::String
    placeholders::Vector{Symbol}
end


function sample_bridging_words_tps(vocab::Vector{String}, c::Int)

    bridging_count = round(Int, linear_extrapolate(
        c,
        min_bridgeword_count,
        bridgeword_count_complexity_100;
        cmin = 1,
        cmid = 100
    ))

    bridging_count = min(bridging_count, length(vocab))

    bridging = sample(vocab, bridging_count; replace=false)

    #remove bridging words from the main vocabulary
    bridging_set = Set(bridging)
    remainder = filter(w -> !(w in bridging_set), vocab)

    return bridging, remainder
end




function build_master_vocabulary_tps(complexity::Int)::Vector{String}
    alpha = sample_alphabet(
        complexity,
        alphabet_unicode_start_ind,
        min_alphabet_size,
        alphabet_size_complexity_100
    )

    vocab = sample_vocabulary(
        complexity,
        alpha,
        min_vocabulary_size,
        vocabulary_size_complexity_100,
        min_word_size,
        word_size_complexity_100
    )
    
    shuffle!(vocab)
    return vocab
end



function build_placeholder_dict_tps(vocab::Vector{String})::Dict{Symbol, Vector{String}}
    #shuffle the vocab, pick first N for :SUBJ, next M for :VERB, next L for :ADJ, etc.
    shuffle!(vocab)
    n = length(vocab)
    #partition
    n_subj = min(round(Int, 0.25*n), n)
    n_verb = min(round(Int, 0.25*n), n - n_subj)
    n_adj  = min(round(Int, 0.25*n), n - n_subj - n_verb)
    #rest for :OBJ
    n_obj  = n - (n_subj + n_verb + n_adj)

    subjects = vocab[1:n_subj]
    verbs    = vocab[n_subj+1 : n_subj + n_verb]
    adjs     = vocab[n_subj + n_verb + 1 : n_subj + n_verb + n_adj]
    objs     = vocab[n_subj + n_verb + n_adj + 1 : end]

    return Dict(
        :SUBJECT  => subjects,
        :VERB     => verbs,
        :ADJECTIVE => adjs,
        :OBJECT   => objs
    )
end



function fill_template(
    tmpl::TextTemplate,
    placeholder_dict::Dict{Symbol, Vector{String}};
    deterministic::Bool=false,
    placeholder_counters::Dict{Symbol,Int}=Dict{Symbol,Int}()
)::String

    line = tmpl.text
    for sym in tmpl.placeholders
        values = get(placeholder_dict, sym, String[])


        if isempty(values)
            line = replace(line, "{"*string(sym)*"}" => "???")
            continue
        end

        # pick a word
        chosen = ""
        if !deterministic
            chosen = rand(values)
        else
            # e.g. do round-robin or always first
            idx = get(placeholder_counters, sym, 1)
            chosen = values[idx]
            # increment
            idx = (idx % length(values)) + 1
            placeholder_counters[sym] = idx
        end

        line = replace(line, "{"*string(sym)*"}" => chosen)
    end
    return line
end



function build_random_templates(
    n::Int,
    available_placeholders::Vector{Symbol};
    bridging_words::Vector{String} = ["the", "a", "some", "quite"],
    max_placeholders_in_template::Int = 4
)::Vector{TextTemplate}

    templates = Vector{TextTemplate}(undef, n)

    for i in 1:n
        
        n_place = rand(1:max_placeholders_in_template)
        
        chosen_placeholders = sample(available_placeholders, n_place; replace=true) #rand(available_placeholders, n_place; replace=true)

        parts = String[]
        for ph in chosen_placeholders
            push!(parts, rand(bridging_words))
            push!(parts, "{" * string(ph) * "}")
        end

        push!(parts, rand(bridging_words))

        tmpl_str = join(parts, " ") * "."  # e.g. "the {SUBJECT} a {VERB} some {OBJECT}."

        placeholders = collect(chosen_placeholders)

        templates[i] = TextTemplate(tmpl_str, placeholders)
    end

    return templates
end



function write_tps_jsonl(lines::Vector{String}, filename::String)
    open(filename, "w") do io
        for line in lines
            write(io, "{\"text\":\"$line\"}\n")
        end
    end
    @info "Wrote $(length(lines)) lines to $filename"
end


function split_and_write_tps_jsonl(lines::Vector{String}, basefile::String)

    shuffle!(lines)
    tot = length(lines)
    ntrain = floor(Int, 0.8 * tot)
    ntest  = floor(Int, 0.1 * tot)
    nval   = tot - ntrain - ntest

    train_lines = lines[1:ntrain]
    test_lines  = lines[ntrain+1 : ntrain+ntest]
    val_lines   = lines[ntrain+ntest+1 : end]

    write_tps_jsonl(train_lines, basefile * "_train.jsonl")
    write_tps_jsonl(test_lines,  basefile * "_test.jsonl")
    write_tps_jsonl(val_lines,   basefile * "_val.jsonl")
end


"""
    generate_tps_corpus(
        complexity::Int,
        num_lines::Int;
        output_dir::String = ".",
        base_name::String = "MyTPS",
        n_templates::Int = 10,
        max_placeholders_in_template::Int = 4,
        deterministic::Bool = false
    ) -> Nothing

Generates a synthetic text corpus by filling randomly constructed templates with vocabulary 
tokens. The corpus is split into training, testing, and validation sets (80/10/10) and saved 
as `.jsonl` files.

# Arguments

- `complexity::Int`: Governs the size of the vocabulary and the number of available “bridging words.”
  Higher values increase the overall variety of tokens.
- `num_lines::Int`: Total number of lines (sentences) to generate. These lines are then split 
  into train (80%), test (10%), and validation (10%) sets.
- `output_dir::String`: Directory path to which the `.jsonl` files are written (default: `"."`).
- `base_name::String`: Base prefix for output files, e.g., `<base_name>_train.jsonl`, 
  `<base_name>_test.jsonl`, and `<base_name>_val.jsonl` (default: `"MyTPS"`).
- `n_templates::Int`: Number of randomly generated templates to build (default: `10`). 
  Each template specifies a textual skeleton with placeholder slots.
- `max_placeholders_in_template::Int`: Maximum number of placeholder tokens each template 
  can contain (default: `4`). These placeholders are drawn from a set of roles (e.g., `SUBJECT`, 
  `VERB`, `ADJECTIVE`, `OBJECT`).
- `deterministic::Bool`: If `true`, placeholders in each template are filled using a 
  systematic (round-robin) approach. If `false`, placeholders are chosen randomly from 
  the available dictionary.

# Description

1. **Vocabulary & Bridging Words**  
   - A base vocabulary is built according to `complexity`. 
   - A subset of the vocabulary is designated as “bridging words,” which act as connecting tokens 
     (e.g., `"the"`, `"some"`) for the templates.
   - The remainder of the vocabulary is partitioned into roles for placeholders 
     (e.g., `:SUBJECT`, `:VERB`, `:ADJECTIVE`, `:OBJECT`).

2. **Template Construction**  
   - `n_templates` are generated, each containing up to `max_placeholders_in_template` placeholders. 
   - Between placeholders, random bridging words (or other connectors) are inserted to form a 
     base template string (e.g., `"the {SUBJECT} a {VERB} some {OBJECT}."`).

3. **Filling Templates**  
   - For each of the `num_lines` text samples, one template is selected (either in a round-robin 
     fashion if `deterministic=true`, or randomly otherwise).
   - The placeholders in that template are then filled with actual words from the assigned 
     placeholder dictionaries. 
   - A round-robin strategy ensures systematic coverage of each placeholder’s vocabulary, while 
     random selection injects more variation.

4. **Output Splitting & JSONL Writing**  
   - All generated lines are shuffled, then split into 80% training, 10% testing, and 10% validation sets.
   - Three `.jsonl` files are created with filenames based on `base_name`: 
     `"<base_name>_train.jsonl"`, `"<base_name>_test.jsonl"`, and `"<base_name>_val.jsonl"`.
   - Each line in these files is a single JSON object containing the text (e.g., `{"text": "the cat ate some fish."}`).

# Returns

Nothing. The final corpus is written to disk in JSON Lines format.

# Example

```julia
generate_tps_corpus(
    50,                          # complexity
    100;                         # num_lines
    output_dir = "./my_outputs", # directory for output JSONL files
    base_name = "TemplatedTest", # base prefix for output filenames
    n_templates = 5,             # how many random templates to generate
    max_placeholders_in_template = 4,  # up to 4 placeholders per template
    deterministic = false        # if true, fill placeholders round-robin instead of randomly
)

"""
function generate_tps_corpus(
                    complexity::Int,
                    num_lines::Int;
                    output_dir::String=".",
                    base_name::String="MyTPS",
                    n_templates::Int=10,
                    max_placeholders_in_template::Int=4,
                    deterministic::Bool=false
                )::Nothing

    #validate and parse integer arguments
    local_complexity  = try_to_get_integer(complexity)
    local_num_lines   = try_to_get_integer(num_lines)
    local_n_templates = try_to_get_integer(n_templates)
    local_max_placeholders = try_to_get_integer(max_placeholders_in_template)

    #check if they were all parsed successfully
    if local_complexity === nothing || local_complexity <= 0
        error("`complexity` must be a positive integer. Received `$(complexity_arg)`.")
    end
    if local_num_lines === nothing || local_num_lines < 1
        error("`num_lines` must be a positive integer. Received `$(num_lines_arg)`.")
    end
    if local_n_templates === nothing || local_n_templates < 1
        error("`n_templates` must be a positive integer. Received `$(n_templates_arg)`.")
    end
    if local_max_placeholders === nothing || local_max_placeholders < 0
        error("`max_placeholders_in_template` must be non-negative. Received `$(max_placeholders_in_template_arg)`.")
    end

    #reassign to validated values
    complexity = local_complexity
    num_lines = local_num_lines
    n_templates = local_n_templates
    max_placeholders_in_template = local_max_placeholders

    #main logic
    vocab = build_master_vocabulary_tps(complexity)

    bridging_words, remainder_vocab = sample_bridging_words_tps(vocab, complexity)

    ph_dict = build_placeholder_dict_tps(remainder_vocab)

    #placeholders from `ph_dict` keys
    available_placeholders = collect(keys(ph_dict))

    #bridging_words can be extended or replaced with bigger sets
    templates = build_random_templates(
        n_templates,
        available_placeholders;
        bridging_words = bridging_words,
        max_placeholders_in_template = max_placeholders_in_template
    )

    lines = String[]

    #if deterministic keep counters so each placeholder can do round-robin
    placeholder_counters = Dict{Symbol,Int}()

    for i in 1:num_lines

        local_tmpl = deterministic ? templates[1 + mod(i-1, n_templates)] : rand(templates)

        line = fill_template(
            local_tmpl,
            ph_dict; 
            deterministic=deterministic,
            placeholder_counters=placeholder_counters
        )
        push!(lines, line)
    end

    base_path = joinpath(output_dir, base_name)
    split_and_write_tps_jsonl(lines, base_path)

    return nothing
end





