using Documenter
using BenchmarkDataNLP

makedocs(
    sitename = "BenchmarkDataNLP",
    format =  Documenter.HTML(),
    modules = [BenchmarkDataNLP],
)

deploydocs(
    repo = "github.com/mantzaris/BenchmarkDataNLP.jl.git"
)
