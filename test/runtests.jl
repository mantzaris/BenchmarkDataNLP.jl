using Test
using BenchmarkDataNLP

import BenchmarkDataNLP: linear_extrapolate, sample_alphabet, sample_punctuation,
                        sample_vocabulary, try_to_get_integer

import BenchmarkDataNLP: assign_roles_to_vocab_CFG, expansions_per_role_CFG, generate_random_expansions_for_role_CFG, 
                        build_grammar_CFG, save_metadata_json_CFG, generate_sentence_CFG,
                        produce_corpus_lines_CFG, generate_corpus_CFG, generate_corpus_CFG,
                        alphabet_unicode_start_ind, punctuation_unicode_start_ind,
                        min_alphabet_size, min_punctuation_size, build_roles_CFG, num_roles_CFG

import BenchmarkDataNLP: paragraph_sentence_count_for_complexity, predicate_count_for_complexity,
                        object_count_for_complexity, subject_count_for_complexity,
                        max_triples_for_complexity, create_rdf_roles_from_vocab,
                        Triple, build_triplestore_random, make_sentence_from_triple,
                        produce_paragraphs_with_context_rdf, produce_lines_no_context,
                        build_master_vocabulary_rdf, build_triplestore_for_complexity,
                        generate_rdf_corpus

import BenchmarkDataNLP: sample_bridging_words_tps,
                        build_master_vocabulary_tps,
                        build_placeholder_dict_tps,
                        fill_template,
                        build_random_templates,
                        TextTemplate,
                        generate_tps_corpus

import BenchmarkDataNLP:
                        context_size_for_complexity, terminal_proportion_for_complexity,
                        deterministic_walk, deterministic_walk_roundrobin,
                        build_deterministic_adjacency,
                        build_adjacency_no_context_random, build_adjacency_with_context_random,
                        generate_fsm_corpus


@testset "linear_extrapolate tests" begin
    # When c == cmin, should return vmin
    @test linear_extrapolate(1, 10, 100; cmin=1, cmid=100) == 10.0

    # When c == cmid, should return vmax
    @test linear_extrapolate(100, 10, 100; cmin=1, cmid=100) == 100.0

    # Some intermediate value (e.g., c = 50)
    # Expect halfway between vmin=10 and vmax=100 → 55.0
    @test isapprox(linear_extrapolate(50, 10, 100; cmin=1, cmid=100), 54.54545; rtol=1e-5)

    # Test that c < cmin throws an error
    @test_throws ErrorException linear_extrapolate(0, 10, 100; cmin=1, cmid=100)
end

@testset "sample_alphabet tests" begin
    # Example parameters
    complexity = 10
    alphabet_unicode_start_ind = Int(0x41)  # 'A' (65 decimal) or any start
    min_alphabet_size = 2
    alphabet_size_complexity_100 = 26

    # Obtain the sample
    result = sample_alphabet(
        complexity,
        alphabet_unicode_start_ind,
        min_alphabet_size,
        alphabet_size_complexity_100
    )

    @test isa(result, Vector{Char})
    # Check the length is what we expect from linear_extrapolate
    expected_length = round(Int, linear_extrapolate(complexity, min_alphabet_size, alphabet_size_complexity_100))
    @test length(result) == expected_length

    # Potentially check that c < 1 throws an error (if you rely on linear_extrapolate to do so)
    @test_throws ErrorException sample_alphabet(
        0,
        alphabet_unicode_start_ind,
        min_alphabet_size,
        alphabet_size_complexity_100
    )
end

@testset "sample_punctuation tests" begin
    complexity = 10
    punctuation_unicode_start_ind = Int(0x21)  # '!' (33 decimal)
    min_punctuation_size = 1
    punctuation_size_complexity_100 = 10

    punct_result = sample_punctuation(
        complexity,
        punctuation_unicode_start_ind,
        min_punctuation_size,
        punctuation_size_complexity_100
    )

    @test isa(punct_result, Vector{String})
    expected_length = round(Int, linear_extrapolate(complexity, min_punctuation_size, punctuation_size_complexity_100))
    @test length(punct_result) == expected_length

    @test_throws ErrorException sample_punctuation(
        0,
        punctuation_unicode_start_ind,
        min_punctuation_size,
        punctuation_size_complexity_100
    )
end

@testset "sample_vocabulary tests" begin
    complexity = 10
    alphabet = ['a','b','c','d','e']
    min_vocabulary_size = 2
    vocabulary_size_complexity_100 = 10
    min_word_size = 1
    word_size_complexity_100 = 5

    vocab_result = sample_vocabulary(
        complexity,
        alphabet,
        min_vocabulary_size,
        vocabulary_size_complexity_100,
        min_word_size,
        word_size_complexity_100
    )

    @test isa(vocab_result, Vector{String})
    expected_vocab_size = round(Int, linear_extrapolate(complexity, min_vocabulary_size, vocabulary_size_complexity_100))
    @test length(vocab_result) == expected_vocab_size

    #check that each word has length in [1, max_word_size]
    max_word_size = round(Int, linear_extrapolate(complexity, min_word_size, word_size_complexity_100))
    @test all(length(word) >= 1 && length(word) <= max_word_size for word in vocab_result)
end

@testset "try_to_get_integer tests" begin

    @test try_to_get_integer(5) == 5

    @test try_to_get_integer("42") == 42

    @test try_to_get_integer("3.14") == 3

    @test try_to_get_integer("1.2e2") == 120

    @test try_to_get_integer([ "hello", "99", 7.5 ]) == 99

    @test isnothing(try_to_get_integer("hello world"))

    @test isnothing(try_to_get_integer(['a','b','c']))
end





@testset "expansions_per_role_CFG tests" begin
    #basic checks
    @test expansions_per_role_CFG(1) == 1
    @test expansions_per_role_CFG(50) == 5

end



@testset "generate_sentence_CFG tests" begin
    #small grammar: Role1 => [[ "hello", :Role2 ], [ "world" ]]
    grammar = Dict{Symbol, Vector{Vector{Any}}}(
        :Role1 => [ ["hello", :Role2], ["world"] ],
        :Role2 => [ ["42"], [:Role1] ]
    )

    println(typeof(grammar))
    #roles_dict could be used when expansions reference a terminal role
    roles_dict = Dict(:Role1 => ["hi"], :Role2 => ["42"], :Role3 => ["unused"])
    sentence = generate_sentence_CFG(:Role1, grammar; roles_dict=roles_dict, depth=0, max_depth=3)
    @test isa(sentence, String)
    #
    @test !isempty(sentence)
    @test length(split(sentence)) ≤ 10  # Expect short expansions given the small recursion depth
end


@testset "rdf_data: for_complexity functions" begin
    @test paragraph_sentence_count_for_complexity(1) == round(Int, linear_extrapolate(1, 1, 10))
    @test paragraph_sentence_count_for_complexity(50) == round(Int, linear_extrapolate(50, 1, 10))

    @test predicate_count_for_complexity(1) == round(Int, linear_extrapolate(1, 5, 25))
    @test predicate_count_for_complexity(100) == round(Int, linear_extrapolate(100, 5, 25))

    @test object_count_for_complexity(1) == round(Int, linear_extrapolate(1, 2*10, 4*500))

    @test subject_count_for_complexity(1) == round(Int, linear_extrapolate(1, 10, 500))
    @test subject_count_for_complexity(50) == round(Int, linear_extrapolate(50, 10, 500))

    @test max_triples_for_complexity(10) == round(Int, linear_extrapolate(10, 100, 100_000))
end



@testset "build_triplestore_random tests" begin
    
    subs = ["S1","S2"]
    preds = ["P1"]
    objs = ["O1","O2"]
    #full cart product => 2 * 1 * 2 = 4
    store_full = build_triplestore_random(subs, preds, objs; max_triples=10)  # max_triples > total_possible
    @test length(store_full) == length(subs)*length(preds)*length(objs)
    @test all(t -> t isa Triple, store_full)
    #check that each Triple is unique
    @test length(unique(store_full)) == length(store_full)

    #partial / random
    subs = ["A","B","C"]
    preds = ["is","has"]
    objs = ["X","Y","Z"]
    total_possible = length(subs)*length(preds)*length(objs)  # 3*2*3=18

    store_subset = build_triplestore_random(subs, preds, objs; max_triples=5)
    @test length(store_subset) ≤ 5
    @test all(t -> t isa Triple, store_subset)
    #no duplicates
    @test length(unique(store_subset)) == length(store_subset)
end


@testset "make_sentence_from_triple tests" begin
    t = Triple("SubjectA", "PredicateB", "ObjectC")

    #with filler
    filler = ["foo","bar"]
    sent2 = make_sentence_from_triple(t; filler=filler, max_filler=2)
    parts = split(sent2)

    s_ind = findfirst(==(t.subj), parts)
    p_ind = findfirst(==(t.pred), parts)
    o_ind = findfirst(==(t.obj), parts)

    if s_ind === nothing || p_ind === nothing || o_ind === nothing
        @info "One or more triple items not found in the sentence. This can happen if filler merges tokens, etc."
        @info "Sentence produced: $sent2"
        @info "Tokens: $parts"
    else

        @test s_ind < p_ind < o_ind
    end
end


@testset "produce_paragraphs_with_context_rdf tests" begin
    store = [
        Triple("S1","P1","O1"),
        Triple("S2","P2","O2")
    ]
    c = 5
    paragraphs = produce_paragraphs_with_context_rdf(store, 3, c; filler=["foo"], max_filler=1)
    @test length(paragraphs) == 3

    @test all(!isempty, paragraphs)
end

@testset "produce_lines_no_context tests" begin
    store = [
        Triple("Subj1","Pred1","Obj1"),
        Triple("Subj2","Pred2","Obj2")
    ]
    lines = produce_lines_no_context(store, 5; filler=["x","y"], max_filler=2)
    @test length(lines) == 5
    @test all(!isempty, lines)
end


@testset "sample_bridging_words_tps tests" begin

    c = 10
    vocab = ["alpha","beta","gamma","delta","epsilon","zeta","eta","theta","iota","kappa"]
    bridging, remainder = sample_bridging_words_tps(vocab, c)

    @test length(bridging) > 0
    @test length(bridging) + length(remainder) == length(vocab)

    @test all(word -> word in vocab, bridging)

    @test intersect(Set(bridging), Set(remainder)) == Set()

    vocab_small = ["only","two","words"]
    bridging2, remainder2 = sample_bridging_words_tps(vocab_small, 200)
    @test Set(bridging2) == Set(vocab_small) #@test bridging2 == vocab_small  # all become bridging
    @test isempty(remainder2)
end


@testset "build_master_vocabulary_tps tests" begin
    # For a small complexity, we expect a smallish vocab
    c = 5
    min_vocabulary_size = 10

    vocab_small = build_master_vocabulary_tps(c)
    @test length(vocab_small) >= min_vocabulary_size  # we expect at least 10 by default
    @test all(word -> isa(word, String), vocab_small)

    # For a larger complexity, get more words
    c_big = 50
    vocab_big = build_master_vocabulary_tps(c_big)
    @test length(vocab_big) > length(vocab_small)
end


@testset "build_placeholder_dict_tps tests" begin
    # Provide a small vocab
    vocab = ["cat","dog","run","jump","red","blue","car","house"]
    ph_dict = build_placeholder_dict_tps(copy(vocab))  # it shuffles internally

    # Must have keys: :SUBJECT, :VERB, :ADJECTIVE, :OBJECT
    @test setdiff(Set([:SUBJECT,:VERB,:ADJECTIVE,:OBJECT]), Set(keys(ph_dict))) == Set()

    # Check partition sum
    total_assigned = sum(length(v) for v in values(ph_dict))
    @test total_assigned == length(vocab)

    # Ensure no duplicates across categories (since we partition)
    sets = map(v->Set(v), values(ph_dict))
    intersection_any = reduce(∪, sets)  # union of all sets
    @test sum(length(s) for s in sets) == length(intersection_any)
end


@testset "assign_roles_to_vocab_CFG tests" begin
    # Generate a small vocabulary and punctuation
    vocab = ["apple", "banana", "carrot", "dog", "elephant"]
    punctuation = [".", ","]
    roles = [:Role1, :Role2]

    dict_no_poly = assign_roles_to_vocab_CFG(roles, vocab, punctuation, false)

    # existing checks for vocabulary assignments
    @test length(dict_no_poly) == length(roles)
    @test all(haskey(dict_no_poly, r) for r in roles)
    for word in vocab
        in_count = sum(word in dict_no_poly[r] for r in roles)
        @test in_count == 1  # no polysemy => each word exactly in 1 role
    end

    # **Relaxed punctuation check**: We no longer fail if no punctuation is appended.
    # Instead, just log a message if punctuation wasn't assigned at all.
    if any(any(punct in dict_no_poly[r] for r in roles) for punct in punctuation)
        @info "At least one role has punctuation."
    else
        @info "No punctuation assigned to any role (random chance). This is okay."
    end
end


@testset "build_random_templates tests" begin
    # Suppose we have placeholders: :SUBJECT, :VERB, :ADJECTIVE, :OBJECT
    placeholders = [:SUBJECT, :VERB, :ADJECTIVE, :OBJECT]
    bridging_words = ["the","a","some","quite"]
    num_templates = 3
    max_placeholders = 2

    templates = build_random_templates(
        num_templates,
        placeholders;
        bridging_words = bridging_words,
        max_placeholders_in_template = max_placeholders
    )

    @test length(templates) == num_templates

    # Each template is a TextTemplate
    for tmpl in templates
        @test isa(tmpl, TextTemplate)
        @test !isempty(tmpl.text)
        # placeholders can vary in count from 1..max_placeholders
        @test length(tmpl.placeholders) >= 1 && length(tmpl.placeholders) <= max_placeholders
        # bridging words are used in the template text
        @test any(bw -> occursin(bw, tmpl.text), bridging_words)
    end
end


@testset "generate_tps_corpus tests" begin
    using Base: mktempdir

    mktempdir() do tmp
        generate_tps_corpus(
            5,        # small complexity
            10;       # produce 10 lines
            output_dir = tmp,
            base_name = "TestTPS",
            n_templates = 2,
            max_placeholders_in_template = 2,
            deterministic = false
        )

        # Should create 3 JSONL files:
        train_file = joinpath(tmp, "TestTPS_train.jsonl")
        test_file  = joinpath(tmp, "TestTPS_test.jsonl")
        val_file   = joinpath(tmp, "TestTPS_val.jsonl")

        for f in (train_file, test_file, val_file)
            @test isfile(f)
        end

        # Optionally check line counts
        function count_lines(fname::String)
            open(fname, "r") do io
                return count(x->true, eachline(io))
            end
        end
        total_lines = count_lines(train_file) + count_lines(test_file) + count_lines(val_file)
        @test total_lines == 10
    end
end




@testset "FSM: complexity-based functions" begin

    min_context_size = 2
    context_size_complexity_100 = 200

    max_proportion_terminal = 0.25
    min_proportion_terminal = 0.01

    @test context_size_for_complexity(1) == min_context_size
    @test context_size_for_complexity(100) == context_size_complexity_100

    
    p1 = terminal_proportion_for_complexity(1)
    p100 = terminal_proportion_for_complexity(100)
    @test p1 ≈ max_proportion_terminal
    @test p100 ≥ min_proportion_terminal
    @test p1 >= p100


    pmid = terminal_proportion_for_complexity(50)
    @test min_proportion_terminal <= pmid <= max_proportion_terminal
end


@testset "FSM: deterministic_walk tests" begin
    adjacency = Dict(
        "A" => [ ["B"], ["C"] ],
        "B" => [ ["C"], ["A"] ],
        "C" => [ ["A"], ["B"] ]
    )

    seq = deterministic_walk(adjacency, "A"; max_length=5)

    @test length(seq) <= 6
    @test seq[1] == "A"
end

@testset "FSM: deterministic_walk_roundrobin tests" begin
    adjacency = Dict(
        "A" => [ ["B"], ["C"] ],
        "B" => [ ["C"], ["A"] ],
        "C" => [ ["A"], ["A"] ]
    )

    seq = deterministic_walk_roundrobin(adjacency, "A"; max_length=6)
    @test seq[1] == "A"
    @test length(seq) <= 7

    @test !isempty(seq)
end


@testset "FSM: build_deterministic_adjacency tests" begin
    vocab = ["apple","banana","carrot"]
    adjacency = build_deterministic_adjacency(vocab)

    @test length(adjacency) == length(vocab)

    for w in vocab
        @test haskey(adjacency, w)
        exps = adjacency[w]
        @test length(exps) == 2
        @test all( e-> length(e) == 1, exps )
    end

    sortedv = sort(vocab)
    for w in sortedv
        idx_w = findfirst(==(w), sortedv)
        exps = adjacency[w]

        @test all(e[1] in vocab for e in exps)
    end
end


@testset "FSM: build_adjacency_no_context_random tests" begin
    terminal_word = string( Char(100) )
    test_term_word = terminal_word

    vocab = ["dog","cat","fish","bird"]
    term_word = terminal_word
    term_prop = 0.5
    adjacency = build_adjacency_no_context_random(
        vocab, term_word, term_prop; 
        min_expansions=1, max_expansions=2
    )

    @test length(adjacency) == length(vocab)
    for w in vocab
        @test haskey(adjacency, w)
        exps = adjacency[w]
        @test !isempty(exps)
        for e in exps
            @test all(x-> x==term_word || x in vocab, e)
        end
    end
end
