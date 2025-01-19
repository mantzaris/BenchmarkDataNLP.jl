module BenchmarkDataNLP

    using Random
    using JSON

    include("cfg_data.jl")
    include("rdf_data.jl") 

    export generate_corpus_CFG, greet


    
    """

        greet()

    Prints a friendly greeting message to the console.

    Returns nothing
    """
    greet() = println("Hello World! Yours Truly, B.D.NLP")

end  # module BenchmarkDataNLP
