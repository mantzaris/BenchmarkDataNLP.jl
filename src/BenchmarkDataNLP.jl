module BenchmarkDataNLP

    include("cfg_data.jl")

    export generate_corpus_CFG, greet, generate_dataset

    using Random


    
    """

        greet()

    Prints a friendly greeting message to the console.

    Returns nothing
    """
    greet() = println("Hello World! Yours Truly, B.D.NLP")

end  # module BenchmarkDataNLP
