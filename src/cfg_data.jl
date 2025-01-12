include("utilities/data_utilities.jl")

using JSON

# TODO: bring in all the functions to keep it in a single file

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





function assign_roles_to_vocab(roles::Vector{Symbol}, vocab::Vector{String}, 
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



function expansions_per_role(c::Int)::Int
    val = linear_extrapolate(c, min_expansion_size, expansion_size_complexity_100; cmin=1, cmid=100)
    return floor(Int, val)
end


function generate_random_expansions_for_role(role::Symbol, roles::Vector{Symbol},
    roles_dict::Dict{Symbol, Vector{String}}, 
    expansions_count::Int)::Vector{Vector{Any}}

    expansions = Vector{Vector{Any}}()
    for i in 1:expansions_count

        nitems = rand(2:7) # TODO make global constants
        expansion_i = Any[]
        for j in 1:nitems
            if rand() < 0.75 && !isempty(roles_dict[role]) # ! increase probability for more quick terminal symbol
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

function build_grammar(roles::Vector{Symbol}, roles_dict::Dict{Symbol, Vector{String}}, c::Int)
    expansions_count = expansions_per_role(c)
    grammar = Dict{Symbol, Vector{Vector{Any}}}()
    for r in roles
        expansions_for_r = generate_random_expansions_for_role(r, roles, roles_dict, expansions_count)
        grammar[r] = expansions_for_r
    end
    return grammar
end

"""
    save_metadata_json(
        filename::String,
        complexity::Int,
        enable_polysemy::Bool,
        num_sentences::Int,
        base_filename::String,
        alphabet::Vector{Char},
        punctuation::Vector{Char},
        vocabulary::Vector{String},
        roles::Vector{Symbol},
        roles_dict::Dict{Symbol, Vector{String}},
        grammar::Dict{Symbol, Vector{Vector{Any}}}
    )

Serialize the synthetic CFG 'metadata' used to produce corpus lines into a 
single .json file named `filename`.

- Converts all `Symbol` keys/items to `String`.
- Stores a variety of fields: complexity, polysemy, number of sentences, etc.

Example usage:
```julia
# after building everything:
save_metadata_json(
    "MyMetadata.json",
    complexity,
    enable_polysemy,
    num_sentences,
    base_filename,
    alphabet,
    punctuation,
    vocabulary,
    roles,
    roles_dict,
    grammar
)

"""
function save_metadata_json( filename::String, complexity::Int, enable_polysemy::Bool, num_sentences::Int,
                                base_filename::String, alphabet::Vector{Char}, punctuation::Vector{String},
                                vocabulary::Vector{String}, roles::Vector{Symbol}, roles_dict::Dict{Symbol, Vector{String}},
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
        json_str = JSON.json(metadata)
        print(io, json_str)
        JSON.print(io, metadata)
    end
    @info "Saved metadata to $filename"

end

"""
    generate_sentence(start_role::Symbol, grammar::Dict{Symbol, Vector{Vector{Any}}};
                    roles_dict::Dict{Symbol, Vector{String}})
Generate a single line from the grammar by recursively expanding `start_role`.
- If `start_role` has expansions in `grammar`, pick one at random and expand each item.
- If `start_role` is not in `grammar`, try picking a word from `roles_dict[start_role]`.
- If that's empty, return an empty string.

This approach can produce short or long lines depending on the expansions.
"""
function generate_sentence(
    start_role::Symbol,
    grammar::Dict{Symbol, Vector{Vector{Any}}},
    ; 
    roles_dict::Dict{Symbol, Vector{String}},
    depth::Int = 0,
    max_depth::Int = 10 # TODO make global constant
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
                push!(parts, generate_sentence(item, grammar; roles_dict=roles_dict, depth=depth+1, max_depth=max_depth))
            elseif item isa String
                push!(parts, item)
            else
                @warn "Unexpected item type $(typeof(item)) in expansion"
            end
        end
        return join(parts, " ")
    end
end


"""
    produce_corpus_lines(
        grammar::Dict{Symbol, Vector{Vector{Any}}},
        roles_dict::Dict{Symbol, Vector{String}},
        roles::Vector{Symbol},
        num_sentences::Int,
        base_filename::String
    )

Generate `num_sentences` lines from the given grammar. The lines are saved
into a `.jsonl` file named `base_filename * ".jsonl"`.

By default, it uses the *first* role in `roles` as the start symbol for
all lines. If you'd like to pick a random start role each time, replace the
`start_role = first(roles)` logic accordingly.
"""
function produce_corpus_lines(
    grammar::Dict{Symbol, Vector{Vector{Any}}},
    roles_dict::Dict{Symbol, Vector{String}},
    roles::Vector{Symbol},
    num_sentences::Int,
    base_filename::String
)

    lines = Vector{String}(undef, num_sentences)

    for i in 1:num_sentences
        local_start = rand(roles)
        lines[i] = generate_sentence(local_start, grammar; roles_dict=roles_dict)
    end

    # TODO make this 3 times for training / testing /validation
    outfilename = base_filename * ".jsonl"
    open(outfilename, "w") do io
        for line in lines
            write(io, "{\"text\": \"$line\"}\n")
        end
    end

    @info "Wrote $num_sentences lines to $outfilename"
end


function num_roles(c::Int)::Int
    val = linear_extrapolate(c, min_role_size, role_size_complexity_100; cmin=1, cmid=100)
    return floor(Int, val)
end


function build_roles(c::Int)
    nr = num_roles(c)
    roles = [Symbol("Role$i") for i in 1:nr]
    return roles
end


"""
generate_corpus_CFG(; 
    complexity::Int = 100, 
    num_sentences::Int = 100_000, 
    enable_polysemy::Bool = false, 
    base_filename::AbstractString = "MyDataset"
)

Generate a synthetic corpus of context-free grammar–based text data.

# Arguments
- `complexity`: Controls the grammar complexity, vocabulary size, and other parameters 
(e.g., at complexity=100 you might have a 10K-word vocabulary, 200 grammar rules, etc.). After 100 the grammar expansions are less typical of human languages.
- `num_sentences`: The total number of text samples (e.g., lines or sentences) to generate.
- `enable_polysemy`: If `true`, allows words to overlap multiple roles or subroles, introducing 
lexical ambiguity in the generated corpus.
- `base_filename`: Base name for the output files; the function will typically create files 
like `base_filename_training.jsonl`, `base_filename_validation.jsonl`, and 
`base_filename_test.jsonl` depending on how you implement data splitting.

# Usage

```julia
# Example usage:
generate_corpus_CFG(
    complexity       = 100,
    num_sentences    = 100_000,
    enable_polysemy  = false,
    base_filename    = "MyDataset"
)
"""
function generate_corpus_CFG(; complexity::Int = 100, num_sentences::Int = 100_000, 
                                enable_polysemy::Bool = false, base_filename::AbstractString = "CFG_Corpus" )

    if complexity <= 0 || complexity > 1000
        error("Complexity must be >= 1 and <= 1000")
    end

    alphabet = sample_alphabet(complexity,alphabet_unicode_start_ind,min_alphabet_size,alphabet_size_complexity_100)
    punctuation = sample_punctuation(complexity,punctuation_unicode_start_ind,min_punctuation_size,punctuation_size_complexity_100)
    vocabulary = sample_vocabulary(complexity, alphabet,min_vocabulary_size,vocabulary_size_complexity_100,min_word_size,word_size_complexity_100)
    roles = build_roles(complexity)
    roles_dict = assign_roles_to_vocab(roles, vocabulary, punctuation, enable_polysemy)
    grammar = build_grammar(roles, roles_dict, complexity)

    meta_filename = base_filename * "_metadata.json"
    save_metadata_json(
        meta_filename,
        complexity,
        enable_polysemy,
        num_sentences,
        base_filename,
        alphabet,
        punctuation,
        vocabulary,
        roles,
        roles_dict,
        grammar
    )

    produce_corpus_lines(grammar, roles_dict, roles, num_sentences, base_filename)
    return nothing
end
