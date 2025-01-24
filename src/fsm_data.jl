
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

const min_context_size = 2
const context_size_complexity_100 = 200

const max_proportion_terminal = 0.25 #exponential decay with increasing complexity
const min_proportion_terminal = 0.01
const proportion_terminal_complexity_100 = 0.1

const terminal_word = string( Char(100) )



function context_size_for_complexity(c::Int)
    #min_context_size at c=1 to context_size_complexity_100 at c=100
    val = linear_extrapolate(
        c,
        min_context_size,
        context_size_complexity_100;
        cmin = 1,
        cmid = 100
    )
    return round(Int, val)
end


function terminal_proportion_for_complexity(c::Int)
    local_p1   = max_proportion_terminal
    local_p100 = proportion_terminal_complexity_100

    #solve for B:  p(100) = p(1)*exp(B*(100-1)) => B = ln(p(100)/p(1)) / 99
    B = log(local_p100 / local_p1) / 99.0

    # p(c) = p(1)*exp(B*(c - 1))
    proportion = local_p1 * exp(B * (c - 1))
    return max( min_proportion_terminal, round(proportion, digits=3) )
end


function deterministic_walk(adjacency::Dict{String, Vector{Vector{String}}}, 
                            start_word::String;
                            max_length::Int=10)::Vector{String}
    out_seq = String[]
    current = start_word
    steps = 0

    while steps < max_length
        push!(out_seq, current)
        if !haskey(adjacency, current) || isempty(adjacency[current])
            break
        end
        
        expansions = adjacency[current]
        #always pick the first expansion
        chosen = expansions[1]  

        #emit tokens (except possibly the last if using chain logic)
        for i in 1:length(chosen)-1
            push!(out_seq, chosen[i])
        end

        steps += 1
        if !isempty(chosen)
            current = chosen[end]
        else
            break
        end
    end

    return out_seq
end

function deterministic_walk_roundrobin(
    adjacency::Dict{String, Vector{Vector{String}}}, 
    start_word::String;
    max_length::Int=10
)::Vector{String}
    out_seq = String[]
    current = start_word
    steps = 0
    
    #track of which expansion index we are on for each word
    expansion_counters = Dict{String,Int}()
    for k in keys(adjacency)
        expansion_counters[k] = 1  # start at the first expansion
    end

    while steps < max_length
        push!(out_seq, current)
        if !haskey(adjacency, current) || isempty(adjacency[current])
            break
        end

        expansions = adjacency[current]
        #pick expansions[ expansion_counters[current] ]
        idx = expansion_counters[current]
        chosen = expansions[idx]

        #move the counter to the next index, wrap around if needed
        idx = (idx % length(expansions)) + 1
        expansion_counters[current] = idx

        #emit tokens except the last if chain-based
        for i in 1:length(chosen)-1
            push!(out_seq, chosen[i])
        end

        steps += 1
        # next state
        if !isempty(chosen)
            current = chosen[end]
        else
            break
        end
    end

    return out_seq
end


function build_deterministic_adjacency(vocab::Vector{String}) 
    #produce expansions in alphabetical order or some repeatable order
    #ex: each word -> 2 expansions if possible
    adjacency = Dict{String, Vector{Vector{String}}}()
    sortedv = sort(vocab)

    for w in sortedv
        expansions = Vector{Vector{String}}()
        #expansions[1]: next word is the next in sortedv or terminal
        #expansions[2]: next word is the next after next, etc.
        #an example of a purely deterministic structure
        expansions_1 = [ sortedv[ mod( findfirst(==(w), sortedv) + 1, length(sortedv) ) + 1 ] ]
        expansions_2 = [ sortedv[ mod( findfirst(==(w), sortedv) + 2, length(sortedv) ) + 1 ] ]
        adjacency[w] = [ expansions_1, expansions_2 ]
    end

    return adjacency
end

function build_adjacency_no_context_random(
    vocab::Vector{String},
    terminal_word::String,
    terminal_prop::Float64;
    min_expansions::Int=1,
    max_expansions::Int=3
)::Dict{String, Vector{Vector{String}}}

    adjacency = Dict{String, Vector{Vector{String}}}()

    for w in vocab
        # random how many expansions for this word
        n_expansions = rand(min_expansions:max_expansions)
        expansions = Vector{Vector{String}}(undef, n_expansions)

        for i in 1:n_expansions
            if rand() < terminal_prop
                expansions[i] = [terminal_word]
            else
                # pick a random word that isn't w
                possible = filter(x -> x != w, vocab)
                expansions[i] = [rand(possible)]
            end
        end

        adjacency[w] = expansions
    end

    return adjacency
end


function build_adjacency_with_context_random(
    context_words::Vector{String},
    normal_words::Vector{String},
    terminal_word::String,
    terminal_prop::Float64;
    min_expansions::Int=1,
    max_expansions::Int=3,
    max_context_tokens::Int=2
)::Dict{String, Vector{Vector{String}}}

    adjacency = Dict{String, Vector{Vector{String}}}()
    all_words = vcat(context_words, normal_words)

    for w in all_words
        n_expansions = rand(min_expansions:max_expansions)
        expansions = Vector{Vector{String}}(undef, n_expansions)

        for i in 1:n_expansions
            if rand() < terminal_prop
                expansions[i] = [terminal_word]
                continue
            end

            # build a random expansion
            exp = String[]

            if w in normal_words
                # random chance to add up to max_context_tokens from context
                if !isempty(context_words)
                    n_ctx = rand(0:max_context_tokens)
                    for _ in 1:n_ctx
                        push!(exp, rand(context_words))
                    end
                end

                # then add 1 normal word (avoid self if we want)
                possible_normal = filter(x -> x != w, normal_words)
                if !isempty(possible_normal)
                    push!(exp, rand(possible_normal))
                end
            else
                # w is a context word
                # either add 1 normal word, or 1..max_context_tokens more context
                if rand() < 0.5 && !isempty(normal_words)
                    # add exactly 1 normal
                    push!(exp, rand(normal_words))
                else
                    # add 1..max_context_tokens context words
                    if !isempty(context_words)
                        n_ctx = rand(1:max_context_tokens)
                        for _ in 1:n_ctx
                            push!(exp, rand(context_words))
                        end
                    end
                end
            end

            expansions[i] = exp
        end

        adjacency[w] = expansions
    end

    return adjacency
end


function write_jsonl(lines::Vector{String}, filename::String)
    open(filename, "w") do io
        for line in lines
            write(io, "{\"text\":\"$line\"}\n")
        end
    end
    @info "Wrote $(length(lines)) lines to $filename"
end

function split_and_write_jsonl(lines::Vector{String}, basename::String)
    shuffle!(lines)
    tot = length(lines)
    ntrain = floor(Int, 0.8 * tot)
    ntest  = floor(Int, 0.1 * tot)
    nval   = tot - ntrain - ntest

    trainl = lines[1:ntrain]
    testl  = lines[ntrain+1 : ntrain+ntest]
    vall   = lines[ntrain+ntest+1 : end]

    write_jsonl(trainl, basename * "_train.jsonl")
    write_jsonl(testl,  basename * "_test.jsonl")
    write_jsonl(vall,   basename * "_val.jsonl")
end



"""
    generate_fsm_corpus(
        complexity::Int, 
        num_lines::Int;
        output_dir::String=".",
        base_name::String="MyFSM",
        use_context::Bool=false,
        random_adjacency::Bool=false,
        max_length::Int=10
    ) -> Nothing

Generates a synthetic text corpus by constructing a Finite State Machine (FSM) adjacency
structure and "walking" it to produce lines of text. The resulting lines are automatically
split into training, testing, and validation sets (80%, 10%, 10%) and saved as JSON lines
(`.jsonl` files).

# Arguments

- `complexity::Int`: Governs the overall size of the vocabulary and the probability
  of generating terminal (ending) transitions. Higher complexity results in:
  - A larger vocabulary.
  - A lower proportion of transitions that lead immediately to a terminal symbol.
- `num_lines::Int`: Number of total lines (FSM walks) to generate in the corpus.

# Keyword Arguments

- `output_dir::String`: Directory where the JSONL output files are written (default: `"."`).
- `base_name::String`: Base filename for the output files. The function creates three JSONL
  files named `"<base_name>_train.jsonl"`, `"<base_name>_test.jsonl"`, and `"<base_name>_val.jsonl"`.
- `use_context::Bool`: If `true`, the vocabulary is split into “context words” and 
  “normal words,” and context words may appear in expansions more frequently to simulate
  shared or thematic context. If `false`, all words are treated uniformly.
- `random_adjacency::Bool`: Controls whether the FSM adjacency (i.e., expansions from
  each word) is created randomly or deterministically:
  - **`true`**: Each word randomly links to 1–3 possible expansions, some of which might
    be terminal. 
  - **`false`**: Each word deterministically expands (e.g., in sorted order), thus
    producing consistent, repeatable chains.
- `max_length::Int`: The maximum number of expansions (steps) for each walk (default: `10`).
  The walk ends if a terminal is reached or `max_length` expansions are exceeded.

# Description

1. **Vocabulary Construction**:
   - A base alphabet is generated according to the `complexity`.
   - A vocabulary is created from this alphabet, again sized according to `complexity`.
   - If `use_context=true`, part of this vocabulary is designated as “context words,” while
     the remaining words serve as “normal words.”

2. **FSM Adjacency Building**:
   - If `random_adjacency=true`, each word’s expansions are chosen randomly. A certain
     fraction of these expansions lead to a terminal symbol (the fraction decreases as 
     `complexity` increases).
   - Otherwise (for `random_adjacency=false`), expansions follow a deterministic pattern
     (e.g., next words in sorted order).

3. **Line Generation**:
   - For each of the `num_lines`, a starting word is randomly selected.
   - The function performs a round-robin deterministic walk from that starting word up 
     to `max_length` expansions or until a terminal expansion is reached. The sequence
     of tokens visited during this walk is concatenated into a single line of text.

4. **Output**:
   - All generated lines are randomly shuffled and then split into three sets:
     - **Training**: 80%
     - **Testing**: 10%
     - **Validation**: 10%
   - These lines are written in `.jsonl` format as `<base_name>_train.jsonl`, 
     `<base_name>_test.jsonl`, and `<base_name>_val.jsonl`.

# Returns
Nothing. The generated text corpus is written to disk in JSONL format.

# Example

```julia
generate_fsm_corpus(
    50,                # complexity -> larger vocabulary, fewer terminal expansions
    100;               # produce 100 lines
    output_dir=".", 
    base_name="MyFSM",
    use_context=true, 
    random_adjacency=true,
    max_length=12
)

"""
function generate_fsm_corpus(
            complexity::Int, 
            num_lines::Int;
            output_dir::String=".",
            base_name::String="MyFSM",
            use_context::Bool=false,
            random_adjacency::Bool=false,
            max_length::Int=10
        ) :: Nothing


    # --- Input Validation ---
    local_complexity = try_to_get_integer(complexity)
    local_num_lines  = try_to_get_integer(num_lines)
    local_max_length = try_to_get_integer(max_length)

    if local_complexity === nothing || local_complexity <= 0
        error("`complexity` must be a positive integer, but got `$(complexity)`")
    end
    if local_num_lines === nothing || local_num_lines <= 0
        error("`num_lines` must be a positive integer, but got `$(num_lines)`")
    end
    if local_max_length === nothing || local_max_length < 1
        error("`max_length` must be at least 1, but got `$(max_length)`")
    end

    #reassign to ensure we now use the validated integer values
    complexity = local_complexity
    num_lines  = local_num_lines
    max_length = local_max_length

    
    #main logic
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

    term_prop = terminal_proportion_for_complexity(complexity)
    ctx_size  = context_size_for_complexity(complexity)
    ctx_size  = min(ctx_size, length(vocab))  # clamp

    context_words = String[]
    normal_words  = copy(vocab)

    if use_context
        if ctx_size < length(vocab)
            context_words = vocab[1:ctx_size]
            normal_words  = vocab[ctx_size+1:end]
        else
            context_words = copy(vocab)
            normal_words  = String[]
        end
    end

    adjacency = Dict{String, Vector{Vector{String}}}()

    if use_context
        if random_adjacency
            adjacency = build_adjacency_with_context_random(
                context_words,
                normal_words,
                terminal_word,
                term_prop
            )
        else

            adjacency = build_deterministic_adjacency(vcat(context_words, normal_words))
        end
    else
        # no context
        if random_adjacency
            adjacency = build_adjacency_no_context_random(
                normal_words,
                terminal_word,
                term_prop
            )
        else
            # purely deterministic
            adjacency = build_deterministic_adjacency(normal_words)
        end
    end


    lines = String[]
    all_keys = collect(keys(adjacency))
    if isempty(all_keys)
        @warn "Adjacency is empty! No lines produced."
        split_and_write_jsonl(lines, joinpath(output_dir, base_name))
        return nothing
    end

    for i in 1:num_lines
        start = rand(all_keys)
        seq = deterministic_walk_roundrobin(adjacency, start; max_length=max_length)
        push!(lines, join(seq, " "))
    end

    base_path = joinpath(output_dir, base_name)
    split_and_write_jsonl(lines, base_path)

    return nothing
end
