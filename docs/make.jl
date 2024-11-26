using Documenter
using BenchmarkDataNLP

makedocs(
    sitename = "BenchmarkDataNLP",
    format = Documenter.HTML(),
    modules = [BenchmarkDataNLP]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs()
