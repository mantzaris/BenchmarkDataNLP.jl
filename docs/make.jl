using Documenter
using BenchmarkDataNLP

makedocs(
    sitename = "BenchmarkDataNLP",
    format = Documenter.HTML(),
    modules = [BenchmarkDataNLP],
    repo = "https://github.com/mantzaris/BenchmarkDataNLP.jl",
    url = "https://mantzaris.github.io/BenchmarkDataNLP.jl/",
    baseurl = "/BenchmarkDataNLP.jl"
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/mantzaris/BenchmarkDataNLP.jl.git"
)
