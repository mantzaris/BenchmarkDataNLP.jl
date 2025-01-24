using Test
using BenchmarkDataNLP

import BenchmarkDataNLP: linear_extrapolate, sample_alphabet, sample_punctuation,
                        sample_vocabulary, try_to_get_integer



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
