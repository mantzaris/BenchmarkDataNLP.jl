include("data_utilities.jl")

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
const role_size_complexity_100 = 50
const min_expansion_size = 1
const expansion_size_complexity_100 = 20

function sample_alphabet(complexity::Int)
    char_number = round(Int, linear_extrapolate(complexity, min_alphabet_size, alphabet_size_complexity_100; cmin=1, cmid=100))    
    return Char.( alphabet_unicode_start_ind:alphabet_unicode_start_ind+char_number-1 )
end

function sample_punctuation(complexity::Int)
    char_number = round(Int, linear_extrapolate(complexity, min_punctuation_size, punctuation_size_complexity_100; cmin=1, cmid=100))
    return Char.( punctuation_unicode_start_ind:punctuation_unicode_start_ind+char_number-1 )
end

function sample_vocabulary(complexity::Int, alphabet::Vector{Char})::Vector{String}
    vocabulary_size = round(Int, linear_extrapolate(complexity, min_vocabulary_size, vocabulary_size_complexity_100; cmin=1, cmid=100))
    max_word_size = round(Int, linear_extrapolate(complexity, min_word_size, word_size_complexity_100; cmin=1, cmid=100))

    words = Vector{String}(undef, vocabulary_size)

    # * ensure in future that words are unique
    # * distribution on word size
    for i in 1:vocabulary_size
        wlen = rand(1:max_word_size)
        # sample wlen chars from the alphabet
        wchars = rand(alphabet, wlen)
        words[i] = join(wchars)
    end

    return words
end


function num_roles(c::Int)::Int
    val = linear_extrapolate(c, min_role_size, role_size_complexity_100; cmin=1, cmid=100)
    return floor(Int, val)
end

function expansions_per_role(c::Int)::Int
    val = linear_extrapolate(c, min_expansion_size, expansion_size_complexity_100; cmin=1, cmid=100)
    return floor(Int, val)
end

function build_roles(c::Int)
    nr = num_roles(c)
    roles = [Symbol("Role$i") for i in 1:nr]
    return roles
end

function assign_roles_to_vocab(roles::Vector{Symbol}, vocab::Vector{String}, polysemy::Bool)
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
    return roles_dict
end

function generate_random_expansions_for_role(role::Symbol, roles::Vector{Symbol},
        roles_dict::Dict{Symbol, Vector{String}}, expansions_count::Int)::Vector{Vector{Any}}
    
    expansions = Vector{Vector{Any}}()
    for i in 1:expansions_count
        
        nitems = rand(2:6) # ? can make the expansions lover
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

function build_grammar(roles::Vector{Symbol}, roles_dict::Dict{Symbol, Vector{String}}, c::Int)
    expansions_count = expansions_per_role(c)
    grammar = Dict{Symbol, Vector{Vector{Any}}}()
    for r in roles
        expansions_for_r = generate_random_expansions_for_role(r, roles, roles_dict, expansions_count)
        grammar[r] = expansions_for_r
    end
    return grammar
end

