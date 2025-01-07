include("utilities/cfg_parameters.jl")

struct CFGSpec
    complexity::Int               # e.g., 0 - 100 (or higher)
    polysemy::Bool                # enable/disable overlap of words among roles
    num_sentences::Int

    alphabet::Vector{Char}        # characters used for generating words
    punctuation::Vector{Char}     # punctuation symbols
    vocabulary::Vector{String}    # master list of generated words
    roles::Dict{Symbol, Vector{String}}  # each symbol -> subset of vocabulary
    # TODO add subroles
    grammar_rules::Vector{Any}    # container for your CFG production rules
    
    user_filename::String #complexity will be part of the file name too
    rng::Random.AbstractRNG
end

"""
generate_corpus_CFG(; 
    complexity::Int = 100, 
    num_sentences::Int = 100_000, 
    enable_polysemy::Bool = false, 
    base_filename::AbstractString = "MyDataset"
)

Generate a synthetic corpus of context-free grammar–based text data.

# Arguments
- `complexity`: Controls the grammar complexity, vocabulary size, and other parameters 
(e.g., at complexity=100 you might have a 10K-word vocabulary, 200 grammar rules, etc.). After 100 the grammar expansions are less typical of human languages.
- `num_sentences`: The total number of text samples (e.g., lines or sentences) to generate.
- `enable_polysemy`: If `true`, allows words to overlap multiple roles or subroles, introducing 
lexical ambiguity in the generated corpus.
- `base_filename`: Base name for the output files; the function will typically create files 
like `base_filename_training.jsonl`, `base_filename_validation.jsonl`, and 
`base_filename_test.jsonl` depending on how you implement data splitting.

# Usage

```julia
# Example usage:
generate_corpus_CFG(
    complexity       = 100,
    num_sentences    = 100_000,
    enable_polysemy  = false,
    base_filename    = "MyDataset"
)
"""
function generate_corpus_CFG(; complexity::Int = 100, num_sentences::Int = 100_000, 
        enable_polysemy::Bool = false, base_filename::AbstractString = "MyDataset" )

    if complexity <= 0 || complexity > 1000
        error("Complexity must be >= 1 and <= 1000")
    end

    
    
    @info "Called generate_corpus_CFG with the following parameters:" 
    @info " complexity = $complexity" 
    @info " num_sentences = $num_sentences" 
    @info " enable_polysemy = $enable_polysemy" 
    @info " base_filename = $base_filename" 
end
