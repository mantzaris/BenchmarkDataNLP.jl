module BenchmarkDataNLP

    using Random
    using JSON

    include("utilities/data_utilities.jl")
    include("cfg_data.jl")
    include("rdf_data.jl")
    include("fsm_data.jl")
    include("tps_data.jl")

    export generate_corpus_CFG, generate_rdf_corpus, generate_fsm_corpus, generate_tps_corpus


end  # module BenchmarkDataNLP
