module BenchmarkDataNLP

    using Random
    using JSON

    include("utilities/data_utilities.jl")
    include("cfg_data.jl")
    include("rdf_data.jl")
    include("fsm_data.jl")

    export generate_corpus_CFG, generate_rdf_corpus, generate_fsm_corpus, greet


    
    """

        greet()

    Prints a friendly greeting message to the console.

    Returns nothing
    """
    greet() = println("Hello World! Yours Truly, B.D.NLP")

end  # module BenchmarkDataNLP
