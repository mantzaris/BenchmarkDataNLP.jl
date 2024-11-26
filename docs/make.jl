using Documenter
using BenchmarkDataNLP

DocMeta.setdocmeta!(BenchmarkDataNLP, :DocTestSetup, :(using BenchmarkDataNLP); recursive=true)


makedocs(
    modules = [BenchmarkDataNLP],
    format =  Documenter.HTML(),
    sitename="BenchmarkDataNLP.jl",
    pages = [
        "Home" => "index.md",
        # Add more pages as needed
    ],
    authors = "Alexander V. Mantzaris",
)

deploydocs(
    repo = "github.com/mantzaris/BenchmarkDataNLP.jl.git"
)
