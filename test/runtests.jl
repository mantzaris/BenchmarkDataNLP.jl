using Test
using BenchmarkDataNLP

@testset "BenchmarkDataNLP Tests" begin
    # Test the greet function
    @test greet() === nothing  # greet() should return nothing

    # Test the add_random_suffix function
    result = add_random_suffix("test")
    @test startswith(result, "test")
    @test length(result) == length("test") + 5  # random suffix has length 5

    # Test the repeat_string function
    @test repeat_string("hi", 3) == "hihihi"
end
