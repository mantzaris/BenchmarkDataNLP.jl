using Documenter
using BenchmarkDataNLP

DocMeta.setdocmeta!(BenchmarkDataNLP, :DocTestSetup, :(using BenchmarkDataNLP); recursive=true)


makedocs(
    modules = [BenchmarkDataNLP],
    authors = "Alexander V. Mantzaris",
    sitename="BenchmarkDataNLP.jl",
    format =  Documenter.HTML(),
    pages = [
        "Home" => "index.md",
        # Add more pages as needed
    ],
)

deploydocs(
    repo = "github.com/mantzaris/BenchmarkDataNLP.jl.git",
)
