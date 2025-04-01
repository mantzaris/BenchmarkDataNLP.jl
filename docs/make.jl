using Documenter
using BenchmarkDataNLP

DocMeta.setdocmeta!(BenchmarkDataNLP, :DocTestSetup, :(using BenchmarkDataNLP); recursive=true)


makedocs(
    authors = "Alexander V. Mantzaris",
    sitename="BenchmarkDataNLP.jl",
    format =  Documenter.HTML(;
        canonical="https://mantzaris.github.io/BenchmarkDataNLP.jl",
        edit_link="main",
        assets=String[],
    ),
    pages = [
        "Home" => "index.md",
        # Add more pages as needed
    ],    
)

deploydocs(
    repo = "github.com/mantzaris/BenchmarkDataNLP.jl",
    devbranch="main",
)
