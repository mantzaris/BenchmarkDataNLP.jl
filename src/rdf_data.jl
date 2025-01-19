include("utilities/data_utilities.jl")


const type_num_complexity_100 = 10
const predicates_num_complexity_100 = 20

using Random


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




# Simple struct for storing a random triple
struct Triple
    subj::String
    pred::String
    obj::String
end


###############################################################################
# Build random triples (purely from your vocabulary, ignoring domain/range).
# For example, produce c*10 lines.
###############################################################################
function build_random_triples(vocab::Vector{String}, c::Int)::Vector{Triple}
    # up to 20 synthetic predicate names
    npreds = min(20, max(1, c ÷ 5))
    preds  = [":pred$(i)" for i in 1:npreds]

    ntrip = c * 10
    store = Vector{Triple}(undef, ntrip)
    # TODO fix to not overlap between subject and object, partial overlap only
    for i in 1:ntrip
        s = rand(vocab)
        p = rand(preds)
        o = rand(vocab)
        store[i] = Triple(s, p, o)
    end
    return store
end

# -------------------------------------------------------------------
# Convert a triple -> a synthetic line by adding random filler tokens
# around (subj, pred, obj). E.g. if maxFiller=3, we can have up to 3
# filler tokens before subj, 3 between subj & pred, etc.
# -------------------------------------------------------------------
function triple_to_line_synthetic(
    t::Triple,
    filler::Vector{String};
    maxFiller::Int=3
)::String
    # pick how many filler tokens appear in each slot
    # TODO sample the number of n1...nk
    n1 = rand(0:maxFiller)  # before subj
    n2 = rand(0:maxFiller)  # between subj & pred
    n3 = rand(0:maxFiller)  # between pred & obj
    n4 = rand(0:maxFiller)  # after obj

    # helper to pick random filler tokens
    function rf(k::Int)
        return k == 0 ? String[] : sample(filler, k; replace=true)
    end

    tokens = String[]

    # chunk 1: filler, then subj
    append!(tokens, rf(n1))
    push!(tokens, t.subj)
    append!(tokens, rf(n2))

    # chunk 2: pred, then filler
    push!(tokens, t.pred)
    append!(tokens, rf(n3))

    # chunk 3: obj, then filler
    push!(tokens, t.obj)
    append!(tokens, rf(n4))

    return join(tokens, " ") * "."
end

# -------------------------------------------------------------------
# Produce lines from the triple store
# If enable_context=true, pick only triples referencing previously
# used entity names (like a "context" approach).
# -------------------------------------------------------------------
function produce_rdf_lines(
    store::Vector{Triple},
    filler::Vector{String},
    num_sentences::Int;
    enable_context::Bool=false,
    maxFiller::Int=3
)::Vector{String}
    lines = Vector{String}(undef, num_sentences)
    active_ents = Set{String}()

    for i in 1:num_sentences
        chosen = if enable_context && !isempty(active_ents)
            # filter store for triples referencing active entities
            possible = filter(t -> (t.subj in active_ents || t.obj in active_ents), store)
            isempty(possible) ? rand(store) : rand(possible)
        else
            rand(store)
        end

        lines[i] = triple_to_line_synthetic(chosen, filler; maxFiller=maxFiller)

        # update context
        push!(active_ents, chosen.subj, chosen.obj)
    end

    return lines
end

# -------------------------------------------------------------------
# Shuffle lines, split into train/test/val, then write .jsonl
# -------------------------------------------------------------------
function write_corpus_jsonl(
    lines::Vector{String},
    outdir::AbstractString,
    basefile::AbstractString
)
    shuffle!(lines)
    tot = length(lines)
    train_count = Int(floor(0.8 * tot))
    test_count  = Int(floor(0.1 * tot))
    val_count   = tot - train_count - test_count

    trainl = lines[1:train_count]
    testl  = lines[train_count+1 : train_count+test_count]
    vall   = lines[train_count+test_count+1 : end]

    _write_jsonl(trainl, joinpath(outdir, basefile*"_training.jsonl"))
    _write_jsonl(testl,  joinpath(outdir, basefile*"_testing.jsonl"))
    _write_jsonl(vall,   joinpath(outdir, basefile*"_validation.jsonl"))
end

function _write_jsonl(lines::Vector{String}, fname::String)
    open(fname, "w") do io
        for line in lines
            write(io, "{\"text\": \"$line\"}\n")
        end
    end
    @info "Wrote $(length(lines)) lines to $fname"
end

# -------------------------------------------------------------------
# Main user-facing function
# - We'll call sample_alphabet, sample_vocabulary, etc. from data_utilities
#   (which you import) to build 'alphabet' & 'vocabulary'
# - Then we build random triples, produce lines, write .jsonl
# -------------------------------------------------------------------
#
# generate_rdf_corpus(
#     50,
#     200;
#     output_dir=".",
#     base_filename="MySyntheticRDF",
#     enable_context=true,
#     use_punctuation=true,
#     maxFiller=4
# )
function generate_rdf_corpus(
    complexity::Int=50,
    num_sentences::Int=100;
    output_dir::AbstractString=".",
    base_filename::AbstractString="RDF_Corpus",
    enable_context::Bool=false,
    use_punctuation::Bool=true,
    maxFiller::Int=3
)
    # (1) build an alphabet from your data utilities
    alphabet = sample_alphabet(
        complexity,
        alphabet_unicode_start_ind,
        min_alphabet_size,
        alphabet_size_complexity_100
    )

    # (2) build a vocabulary from that alphabet
    vocab = sample_vocabulary(
        complexity,
        alphabet,
        min_vocabulary_size,
        vocabulary_size_complexity_100,
        min_word_size,
        word_size_complexity_100
    )

    # (3) optionally sample punctuation from data_utilities
    filler = copy(vocab)
    if use_punctuation
        punct = sample_punctuation(
            complexity,
            punctuation_unicode_start_ind,
            min_punctuation_size,
            punctuation_size_complexity_100
        )
        append!(filler, punct)
    end

    # (4) build random triple store from the vocabulary
    store = build_random_triples(vocab, complexity)

    # (5) produce lines
    lines = produce_rdf_lines(
        store,
        filler,
        num_sentences;
        enable_context=enable_context,
        maxFiller=maxFiller
    )

    # (6) write .jsonl
    write_corpus_jsonl(lines, output_dir, base_filename)

    return nothing
end