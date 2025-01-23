# Consistent Knowledge Graph, Pre-Build a Triple Store

using JSON
using Random
using StatsBase

# TODO put into utilities
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

#new
const min_subject_count = 10
const subject_count_complexity_100 = 500

const min_predicate_count = 5
const predicate_count_complexity_100 = 25

const min_triple_count = 100
const max_triple_count_complexity_100 = 100_000

const paragraph_sentence_size_min = 1
const paragraph_sentence_size_complexity_100 = 10


struct Triple
    subj::String
    pred::String
    obj::String
end


function paragraph_sentence_count_for_complexity(c::Int)
    return round(Int, linear_extrapolate(c, paragraph_sentence_size_min, paragraph_sentence_size_complexity_100))
end

function predicate_count_for_complexity(c::Int)
    return round(Int, linear_extrapolate(c, min_predicate_count, predicate_count_complexity_100))
end

function object_count_for_complexity(c::Int)
    return round(Int, linear_extrapolate(c, 2*min_subject_count, 4*subject_count_complexity_100))
end

function subject_count_for_complexity(c::Int)
    return round(Int, linear_extrapolate(c, min_subject_count, subject_count_complexity_100))
end

function max_triples_for_complexity(c::Int)
    return round(Int, linear_extrapolate(c, min_triple_count, max_triple_count_complexity_100))
end

function create_rdf_roles_from_vocab(vocab::Vector{String}, c::Int; filler_ratio::Float64 = 0.0)
    shuffle!(vocab)

    nS = subject_count_for_complexity(c)
    nP = predicate_count_for_complexity(c)
    nO = object_count_for_complexity(c)

    if length(vocab) < nS + nP + nO
        @warn "Vocabulary is too small to allocate distinct sets for S,P,O. Using entire vocab in each role!"
        return (copy(vocab), copy(vocab), copy(vocab), String[])
    end

    subjects   = vocab[1:nS]
    predicates = vocab[nS+1 : nS + nP]
    objects    = vocab[nS+nP+1 : nS+nP+nO]

    #filler is the leftover; assign a fraction `filler_ratio` of the leftover to filler, 
    #the rest is unused
    remainder_start = nS + nP + nO + 1
    if remainder_start > length(vocab)
        filler = String[] #no leftover
    else
        leftover = vocab[remainder_start : end]
        n_fill = round(Int, filler_ratio * length(leftover))
        filler = leftover[1:n_fill]
    end

    return (subjects, predicates, objects, filler)
end


function build_triplestore_random(subjects::Vector{String}, predicates::Vector{String}, 
                                    objects::Vector{String}; max_triples::Int=1_000)
    nS = length(subjects)
    nP = length(predicates)
    nO = length(objects)

    total_possible = nS * nP * nO
    if total_possible <= max_triples
        # We can afford the full cart product
        all_triples = Vector{Triple}(undef, 0)
        for s in subjects
            for p in predicates
                for o in objects
                    push!(all_triples, Triple(s, p, o))
                end
            end
        end
        return all_triples
    else
        #a subset do a random approach: sampling (s, p, o) combos until we fill 'max_triples' unique ones
        store = Set{Tuple{String,String,String}}()
        @inbounds while length(store) < max_triples
            s = rand(subjects)
            p = rand(predicates)
            o = rand(objects)
            push!(store, (s,p,o))
            # Potential infinite loop if max_triples > total_possible
            # so let's check for that:
            if length(store) == total_possible
                break #exhausted all combos
            end
        end
        # Now convert each tuple to Triple
        return [Triple(spo[1], spo[2], spo[3]) for spo in store]
    end
end


function build_master_vocabulary(complexity::Int)::Vector{String}
    alpha = sample_alphabet(complexity, alphabet_unicode_start_ind, min_alphabet_size,
                                alphabet_size_complexity_100)

    vocab = sample_vocabulary(complexity, alpha, min_vocabulary_size, vocabulary_size_complexity_100,
                                min_word_size, word_size_complexity_100)

    punct = sample_punctuation(complexity, punctuation_unicode_start_ind, min_punctuation_size,
                                    punctuation_size_complexity_100)

    append!(vocab, punct)
    shuffle!(vocab) #optional

    return vocab
end


function build_triplestore_for_complexity(vocab::Vector{String}, complexity::Int; filler_ratio::Float64=0.0)
    subjects, predicates, objects, filler = create_rdf_roles_from_vocab(vocab, complexity; filler_ratio=filler_ratio)
    mt = max_triples_for_complexity(complexity)
    store = build_triplestore_random(subjects, predicates, objects; max_triples=mt)
    return store, filler
end


function make_sentence_from_triple(t::Triple; filler::Vector{String}=String[], max_filler::Int=0)::String
    n1 = rand(0:max_filler)  # before subj
    n2 = rand(0:max_filler)  # between subj & pred
    n3 = rand(0:max_filler)  # between pred & obj

    tokens = String[]
    append!(tokens, sample(filler, n1; replace=true))
    push!(tokens, t.subj)
    append!(tokens, sample(filler, n2; replace=true))
    push!(tokens, t.pred)
    append!(tokens, sample(filler, n3; replace=true))
    push!(tokens, t.obj)

    return join(tokens, " ") * "."
end

function produce_paragraphs_with_context(store::Vector{Triple}, num_paragraphs::Int, c::Int;
                                            filler::Vector{String}=String[], max_filler::Int=0)::Vector{String}
    lines = String[]

    max_sents_in_paragraph = paragraph_sentence_count_for_complexity(c)

    for p in 1:num_paragraphs
        active = Set{String}() #track used entities in this paragraph
        n_sents = rand(1:max_sents_in_paragraph)
        paragraph_sents = String[]

        for s_idx in 1:n_sents
            possible = filter(t -> (t.subj in active || t.obj in active), store)
            # if none found, pick from full store
            triple = isempty(possible) ? rand(store) : rand(possible)
            # create a sentence
            sent = make_sentence_from_triple(triple; filler=filler, max_filler=max_filler)
            push!(paragraph_sents, sent)

            # update context
            push!(active, triple.subj, triple.obj)
        end

        push!(lines, join(paragraph_sents, " "))
    end

    return lines
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

    train_lines = lines[1:ntrain]
    test_lines  = lines[ntrain+1 : ntrain+ntest]
    val_lines   = lines[ntrain+ntest+1 : end]

    write_jsonl(train_lines, basename * "_train.jsonl")
    write_jsonl(test_lines,  basename * "_test.jsonl")
    write_jsonl(val_lines,   basename * "_val.jsonl")
end

function produce_lines_no_context(store::Vector{Triple}, num_lines::Int; 
                                    filler::Vector{String}=String[], max_filler::Int=0)::Vector{String}
    lines = String[]
    for i in 1:num_lines
        t = rand(store)
        sent = make_sentence_from_triple(t; filler=filler, max_filler=max_filler)
        push!(lines, sent)
    end
    return lines
end




"""
    generate_rdf_corpus(
        complexity::Int,
        num_paragraphs::Int;
        output_dir::String=".",
        base_name::String="MyRDF",
        filler_ratio::Float64=0.0,
        max_filler::Int=0,
        use_context::Bool=false
    ) -> Nothing

Generate a synthetic RDF-based text corpus and automatically split it into 
training, testing, and validation sets. The corpus is saved as `.jsonl` files.

# Arguments
- `complexity::Int`: Controls the scale of the generated vocabulary and triple store. Higher complexity leads 
to a larger vocabulary, more subjects/predicates/objects, and potentially a higher number of triples.
- `num_paragraphs::Int`: The total number of lines (or “paragraphs” if `use_context=true`) to 
produce in the final corpus.
- `output_dir::String`: Directory where output files will be saved (`"."` by default).
- `base_name::String`: Base name for the output files. The function will produce three files named 
`<base_name>_train.jsonl`, `<base_name>_test.jsonl`, and `<base_name>_val.jsonl`.
- `filler_ratio::Float64`: Fraction of the vocabulary leftover (after allocating subjects, predicates, 
and objects) that is used for filler tokens. For example, a value of `0.3` means 30% of the leftover words 
    become filler tokens. A higher ratio produces more distinct filler words you can insert in generated sentences. 
    If this is `0.0`, no extra tokens are dedicated to filler.
- `max_filler::Int`: The maximum number of filler tokens inserted around each subject, 
predicate, or object in a generated sentence. For example, if `max_filler=2`, then up to 
two randomly chosen filler tokens might appear before the subject, between subject and 
predicate, or between predicate and object.
- `use_context::Bool`: If true, generates multi-sentence paragraphs reusing previously 
mentioned entities (subject/object) within each paragraph, introducing some “context.” 
Otherwise, each line is just a single triple-based sentence with no continuity.

# Description
1. **Vocabulary & Triple Store**: Based on `complexity`, the function creates a master vocabulary 
and partitions it into subjects, predicates, objects, and (optionally) filler. A random subset 
of (subject, predicate, object) combinations is then chosen to form a finite triple store.

2. **Text Generation**:
  - If `use_context=false`, each line is a single sentence referencing a randomly picked triple, 
optionally inserting up to `max_filler` filler tokens around the subject/predicate/object.
  - If `use_context=true`, the function produces multi-sentence paragraphs, where each paragraph 
attempts to reuse entities mentioned in prior sentences for added context.

3. **Output**:
  - The resulting lines or paragraphs are shuffled and split into training (80%), testing (10%), 
and validation (10%) sets.
  - Saved as JSON lines in files named `<base_name>_train.jsonl`, `<base_name>_test.jsonl`, 
and `<base_name>_val.jsonl` within `output_dir`.

# Returns
Nothing. The synthetic corpus is written to disk in JSONL format.

# Example

```julia
generate_rdf_corpus(
    50,
    1_000;
    output_dir = ".",
    base_name = "MyRDF",
    filler_ratio = 0.2,
    max_filler = 2,
    use_context = true
)
    
"""
function generate_rdf_corpus(complexity::Int, num_paragraphs::Int; output_dir::String=".",
                                base_name::String="MyRDF", filler_ratio::Float64=0.0,
                                max_filler::Int=0, use_context::Bool=false)
    
    vocab = build_master_vocabulary(complexity)
    store, filler = build_triplestore_for_complexity(vocab, complexity; filler_ratio=filler_ratio)

    lines = if use_context
                produce_paragraphs_with_context(store, num_paragraphs, complexity; filler=filler,
                                                max_filler=max_filler)
        else
                produce_lines_no_context(store, num_paragraphs; filler=filler, max_filler=max_filler)
        end

    base_path = joinpath(output_dir, base_name)
    split_and_write_jsonl(lines, base_path)

    return nothing
end





# generate_rdf_corpus(
#     10,            # complexity
#     100,          # produce 1000 lines or paragraphs
#     output_dir=".",
#     base_name="RDF_Simple",
#     filler_ratio=0.2,
#     max_filler=0,
#     use_context=true
# )