
#TODO test for cycles in grammar roles

using JSON
using StatsBase


const alphabet_unicode_start_ind = 44032 #0xAC00 HANGUL_START = 0xAC00
const min_alphabet_size = 5
const alphabet_size_complexity_100 = 50

const punctuation_unicode_start_ind = 256 #Latin Extended-A block, 0x0100 256 in decimal
const min_punctuation_size = 1
const punctuation_size_complexity_100 = 10

const min_word_size = 5
const word_size_complexity_100 = 20

const min_vocabulary_size = 10
const vocabulary_size_complexity_100 = 10_000

const min_role_size = 2
const role_size_complexity_100 = 100
const min_expansion_size = 1
const expansion_size_complexity_100 = 10
const expansion_nitem_min = 2
const expansion_nitem_max = 6

const sentence_recursion_max_depth = 8



function assign_roles_to_vocab_CFG(roles::Vector{Symbol}, vocab::Vector{String}, 
                                punctuation::Vector{String}, polysemy::Bool)
    roles_dict = Dict{Symbol, Vector{String}}(r => String[] for r in roles)
    for word in vocab
        if polysemy
            # * the word appears in multiple roles, e.g., 1 or 2 roles, generalize more
            chosen = sample(roles, rand([1,2]); replace=false)
            for r in chosen
                push!(roles_dict[r], word)
            end
        else
            chosen = rand(roles)
            push!(roles_dict[chosen], word)
        end
    end

    #punctuation tokens into some roles
    for r in roles
    if rand() < 0.5
    append!(roles_dict[r], punctuation)
    end
    end

    return roles_dict
end



function expansions_per_role_CFG(c::Int)::Int
    val = linear_extrapolate(c, min_expansion_size, expansion_size_complexity_100; cmin=1, cmid=100)
    return floor(Int, val)
end


function generate_random_expansions_for_role_CFG(role::Symbol, roles::Vector{Symbol},
    roles_dict::Dict{Symbol, Vector{String}}, 
    expansions_count::Int)::Vector{Vector{Any}}

    expansions = Vector{Vector{Any}}()
    for i in 1:expansions_count

        nitems = rand(expansion_nitem_min:expansion_nitem_max)
        expansion_i = Any[]
        for j in 1:nitems
            if rand() < 0.8 && !isempty(roles_dict[role]) # ! increase probability for more quick terminal symbol
            # pick a word from this role's vocabulary subset, chance pick a terminal
            push!(expansion_i, rand(roles_dict[role]))
        else
            # reference some other role
            push!(expansion_i, rand(roles))
            end
        end
        push!(expansions, expansion_i)
    end
    return expansions
end

function build_grammar_CFG(roles::Vector{Symbol}, roles_dict::Dict{Symbol, Vector{String}}, c::Int)
    expansions_count = expansions_per_role_CFG(c)
    grammar = Dict{Symbol, Vector{Vector{Any}}}()
    for r in roles
        expansions_for_r = generate_random_expansions_for_role_CFG(r, roles, roles_dict, expansions_count)
        grammar[r] = expansions_for_r
    end
    return grammar
end


#Serialize the synthetic CFG 'metadata' used to produce corpus lines into a 
#single .json file named `filename`.

# - Converts all `Symbol` keys/items to `String`.
# - Stores a variety of fields: complexity, polysemy, number of sentences, etc.

# Example usage:
# ```julia
# # after building everything:
# save_metadata_json_CFG(
#     "MyMetadata.json",
#     complexity,
#     enable_polysemy,
#     num_sentences,
#     base_filename,
#     alphabet,
#     punctuation,
#     vocabulary,
#     roles,
#     roles_dict,
#     grammar
# )
#```
function save_metadata_json_CFG( filename::String, complexity::Int, enable_polysemy::Bool, 
                                num_sentences::Int,
                                base_filename::String, alphabet::Vector{Char}, 
                                punctuation::Vector{String},
                                vocabulary::Vector{String}, roles::Vector{Symbol}, 
                                roles_dict::Dict{Symbol, Vector{String}},
                                grammar::Dict{Symbol, Vector{Vector{Any}}} )

    # 1) Convert `alphabet` and `punctuation` to strings or store them directly as array of chars.
    alphabet_as_strings = string.(alphabet)       # each Char => String
    # punctuation_as_strings = string.(punctuation)
    
    # 2) Convert roles to array of strings
    roles_as_strings = map(string, roles)
    
    # 3) Convert roles_dict to dictionary of string => array of strings
    roles_dict_as_strings = Dict{String, Vector{String}}()
    for (sym, arr) in roles_dict
        roles_dict_as_strings[string(sym)] = arr
    end
    
    grammar_as_strings = Dict{String, Vector{Vector{String}}}()
    for (sym, expansions) in grammar
        expansions_as_strings = Vector{Vector{String}}()
        for expansion in expansions
            converted = String[]
            for item in expansion
                if item isa Symbol
                    push!(converted, string(item))
                elseif item isa String
                    push!(converted, item)
                else
                    push!(converted, string(item))
                end
            end
            push!(expansions_as_strings, converted)
        end
        grammar_as_strings[string(sym)] = expansions_as_strings
    end

    metadata = Dict(
        "complexity"      => complexity,
        "enable_polysemy" => enable_polysemy,
        "num_sentences"   => num_sentences,
        "base_filename"   => base_filename,
        "alphabet"        => alphabet_as_strings,
        "punctuation"     => punctuation, #punctuation_as_strings,
        "roles"           => roles_as_strings,
        "roles_dict"      => roles_dict_as_strings,
        "grammar"         => grammar_as_strings,
        "vocabulary"      => vocabulary
    )

    open(filename, "w") do io
        JSON.print(io, metadata)
    end
    @info "Saved metadata to $filename"

end


# Generate a single line from the grammar by recursively expanding `start_role`.
# - If `start_role` has expansions in `grammar`, pick one at random and expand each item.
# - If `start_role` is not in `grammar`, try picking a word from `roles_dict[start_role]`.
# - If that's empty, return an empty string.

# This approach can produce short or long lines depending on the expansions.
function generate_sentence_CFG(
    start_role::Symbol,
    grammar::Dict{Symbol, Vector{Vector{Any}}},
    ; 
    roles_dict::Dict{Symbol, Vector{String}},
    depth::Int = 0,
    max_depth::Int = sentence_recursion_max_depth
)

    if depth > max_depth # ? we've recursed too far, assume we won't find a terminal
        return ""
    end

    expansions = get(grammar, start_role, nothing)
    if expansions === nothing
        # This role wasn't defined in grammar expansions, so maybe it's a "terminal role"
        words_list = get(roles_dict, start_role, String[])
        if !isempty(words_list)
            return rand(words_list)
        else
            return ""  # fallback if there's truly nothing
        end
    else
        # We do have expansions for this role
        chosen_expansion = rand(expansions)  # e.g. ["someWord", :Role2, ...]
        parts = String[]
        for item in chosen_expansion
            if item isa Symbol
                push!(parts, generate_sentence_CFG(item, grammar; roles_dict=roles_dict, depth=depth+1, max_depth=max_depth))
            elseif item isa String
                push!(parts, item)
            else
                @warn "Unexpected item type $(typeof(item)) in expansion"
            end
        end
        return join(parts, " ")
    end
end


#Generate `num_sentences` lines from the given grammar. The lines are saved into a `.jsonl` file named `base_filename * ".jsonl"`.
# By default, it uses the *first* role in `roles` as the start symbol for
# all lines. If you'd like to pick a random start role each time, replace the
# `start_role = first(roles)` logic accordingly.

function produce_corpus_lines_CFG(
    grammar::Dict{Symbol, Vector{Vector{Any}}},
    roles_dict::Dict{Symbol, Vector{String}},
    roles::Vector{Symbol},
    num_sentences::Int,
    base_filename::String
)
    total_lines = num_sentences    
    lines = Vector{String}(undef, total_lines)
    
    for i in 1:total_lines
        local_start = rand(roles)
        lines[i] = generate_sentence_CFG(local_start, grammar; roles_dict=roles_dict)
    end

    shuffle!(lines)

    train_count = Int(floor(0.8 * total_lines))
    test_count = Int(floor(0.1 * total_lines))
    val_count = total_lines - train_count - test_count

    train_lines = lines[1:train_count]
    test_lines  = lines[train_count+1 : train_count+test_count]
    val_lines   = lines[train_count+test_count+1 : end]

    write_jsonl_CFG(train_lines, base_filename * "_training.jsonl")
    write_jsonl_CFG(test_lines, base_filename * "_testing.jsonl")
    write_jsonl_CFG(val_lines, base_filename * "_validation.jsonl")
end

function write_jsonl_CFG(lines::Vector{String}, filename::String)
    open(filename, "w") do io
        for line in lines
            write(io, "{\"text\": \"$line\"}\n")
        end
    end
    @info "Wrote $(length(lines)) lines to $filename"
end


function num_roles_CFG(c::Int)::Int
    val = linear_extrapolate(c, min_role_size, role_size_complexity_100; cmin=1, cmid=100)
    return floor(Int, val)
end


function build_roles_CFG(c::Int)
    nr = num_roles_CFG(c)
    roles = [Symbol("Role$i") for i in 1:nr]
    return roles
end


"""
    generate_corpus_CFG(
        ; 
        complexity::Int = 100, 
        num_sentences::Int = 100_000, 
        enable_polysemy::Bool = false, 
        output_dir::AbstractString = ".", 
        base_filename::AbstractString = "CFG_Corpus"
    ) -> Nothing

Generate a synthetic corpus of text using a randomly constructed Context-Free Grammar (CFG). 
This function creates a vocabulary (including punctuation), assigns words to various grammar 
roles, builds random expansions for each role, and then recursively expands a start role 
to produce individual text lines. The corpus is randomly shuffled and split into 80% 
training, 10% testing, and 10% validation `.jsonl` files. It also saves a metadata file 
describing the generated grammar.

# Arguments

- `complexity::Int` (default = 100): Controls the overall size and complexity of the grammar 
  and vocabulary. Higher values lead to more roles, more words, and larger expansions 
  (potentially producing lengthier or more varied sentences). 
  - **Range**: 1 ≤ `complexity` ≤ 1000.
  - **Behavior**: 
    - At lower values (≈1–10), the grammar is quite small.
    - At or beyond 100, expansions can become extensive and less “natural.”

- `num_sentences::Int` (default = 100_000): Total number of text lines (sentences) to generate.

- `enable_polysemy::Bool` (default = `false`): If `true`, words may appear in multiple roles, 
  introducing lexical ambiguity. If `false`, each word is assigned to exactly one role.

- `output_dir::AbstractString` (default = `"."`): Directory path to which all output files 
  (the corpus `.jsonl` files and metadata `.json`) are written.

- `base_filename::AbstractString` (default = `"CFG_Corpus"`): Base name for output files. 
  The function writes:
  - `"<base_filename>_metadata.json"`: A JSON file describing the generated grammar, roles, etc.
  - `"<base_filename>_training.jsonl"`, `"<base_filename>_testing.jsonl"`, and 
    `"<base_filename>_validation.jsonl"`: The text corpus in JSON Lines format.

# Description

1. **Vocabulary & Punctuation**  
   A base alphabet is sampled given the `complexity`. Then, punctuation tokens are added. 
   Words are formed by combining characters from the alphabet (the size of the vocabulary 
   also scales with `complexity`).

2. **Role Creation**  
   A set of grammar roles (e.g., `Role1`, `Role2`, ...) is generated. The number of roles 
   grows with `complexity`. 

3. **Role Assignment & Polysemy**  
   - If `enable_polysemy=false`, each word is placed into exactly one role’s vocabulary.  
   - If `enable_polysemy=true`, words may appear in multiple roles (e.g., “bat” might be 
     assigned to both `Noun` and `Verb` roles).

4. **Grammar Construction**  
   - For each role, a number of random expansions is created (scaling with `complexity`).
   - An expansion is a sequence of items, each of which may be another role (non-terminal) 
     or a terminal word. 
   - Recursion depth is limited (`sentence_recursion_max_depth`) to prevent infinite loops 
     if the expansions reference one another excessively.

5. **Sentence Generation**  
   - Each of the `num_sentences` lines is produced by randomly choosing a start role, then 
     recursively expanding it until only terminal words remain or the maximum recursion depth 
     is reached. 
   - The resulting tokens are joined into a single line of text.

6. **Output**  
   - The generated lines are shuffled and split into train (80%), test (10%), and validation 
     (10%) sets. 
   - Three `.jsonl` files are written: `"[base_filename]_training.jsonl"`, 
     `"[base_filename]_testing.jsonl"`, and `"[base_filename]_validation.jsonl"`. 
   - A metadata file, `"[base_filename]_metadata.json"`, captures the grammar, roles, and 
     vocabulary used.

# Returns
Nothing. The corpus (train/test/validation) and a metadata file describing the grammar are 
saved to disk as JSON files.

# Example

```julia
generate_corpus_CFG(
    complexity      = 100, 
    num_sentences   = 100_000, 
    enable_polysemy = true, 
    output_dir      = "/path/to/output", 
    base_filename   = "MyCFGCorpus"
)
```
"""
function generate_corpus_CFG(; complexity::Int = 100, 
                                num_sentences::Int = 100_000, 
                                enable_polysemy::Bool = false, 
                                output_dir::AbstractString = ".", 
                                base_filename::AbstractString = "CFG_Corpus" )

    if complexity <= 0 || complexity > 1000
        error("Complexity must be >= 1 and <= 1000")
    end

    #basic input parsing & validation
    local_complexity   = try_to_get_integer(complexity)
    local_num_sentences = try_to_get_integer(num_sentences)

    #check for valid integer conversion
    if local_complexity === nothing
        error("Could not parse `complexity` as an integer. Received `$(complexity)`")
    end
    if local_num_sentences === nothing
        error("Could not parse `num_sentences` as an integer. Received `$(num_sentences)`")
    end

    #range checks
    if local_complexity < 1 || local_complexity > 1000
        error("`complexity` must be between 1 and 1000. Received $(local_complexity).")
    end
    if local_num_sentences < 1
        error("`num_sentences` must be >= 1. Received $(local_num_sentences).")
    end

    #put values back
    complexity = local_complexity
    num_sentences = local_num_sentences

    #logic for CFG
    alphabet = sample_alphabet(complexity,alphabet_unicode_start_ind,min_alphabet_size,alphabet_size_complexity_100)
    punctuation = sample_punctuation(complexity,punctuation_unicode_start_ind,min_punctuation_size,punctuation_size_complexity_100)
    vocabulary = sample_vocabulary(complexity, alphabet,min_vocabulary_size,vocabulary_size_complexity_100,min_word_size,word_size_complexity_100)
    roles = build_roles_CFG(complexity)
    roles_dict = assign_roles_to_vocab_CFG(roles, vocabulary, punctuation, enable_polysemy)
    grammar = build_grammar_CFG(roles, roles_dict, complexity)

    outpath_base = joinpath(output_dir, base_filename)

    meta_filename = outpath_base * "_metadata.json"
    save_metadata_json_CFG(
        meta_filename,
        complexity,
        enable_polysemy,
        num_sentences,
        outpath_base,
        alphabet,
        punctuation,
        vocabulary,
        roles,
        roles_dict,
        grammar
    )

    produce_corpus_lines_CFG(grammar, roles_dict, roles, num_sentences, outpath_base)
    return nothing
end
