


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


function sample_bridging_words(vocab::Vector{String}, c::Int)

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




function build_master_vocabulary(complexity::Int)::Vector{String}
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



function build_placeholder_dict(vocab::Vector{String})::Dict{Symbol, Vector{String}}
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
    output_dir::String=".",
    base_name::String="MyTPS",
    n_templates::Int=10,
    max_placeholders_in_template::Int=4,
    deterministic::Bool=false
)::Nothing

User-facing function to create a templated corpus, split into train/test/val, 
and save as .jsonl.

# Arguments
- `complexity`: Controls vocabulary size. 
- `num_lines`: How many total lines to generate (will be split 80/10/10).
- `output_dir`: Directory for the output JSONL files.
- `base_name`: File prefix (e.g. "MyTPS_train.jsonl", etc.).
- `n_templates`: Number of random templates to generate.
- `max_placeholders_in_template`: Each template can have up to this many placeholders.
- `deterministic`: If true, placeholders are filled in a systematic/round-robin manner. 
If false, placeholders are chosen randomly from the placeholder dictionary.

# Returns
Nothing. The function writes out train/test/val JSONL files.

# Usage

generate_tps_corpus(50, 100; base_name="TemplatedTest", deterministic=false )

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

    vocab = build_master_vocabulary(complexity)

    bridging_words, remainder_vocab = sample_bridging_words(vocab, complexity)

    ph_dict = build_placeholder_dict(remainder_vocab)

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





