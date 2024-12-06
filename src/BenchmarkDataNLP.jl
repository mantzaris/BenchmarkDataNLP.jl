module BenchmarkDataNLP

    export greet, generate_dataset

    using Random

    """
        greet()

    Prints a friendly greeting message to the console.

    Returns nothing
    """
    greet() = println("Hello World! Yours Truly, B.D.NLP")

    # Define the Context Free Grammar
    struct CFG
        nonterminals::Vector{String}
        terminals::Vector{String}
        productions::Dict{String, Vector{Vector{String}}}
        start_symbol::String
    end

    # Create a simple Context Free Grammar as an example
    function create_cfg()
        nonterminals = ["S", "NP", "VP", "Det", "Noun", "Verb"]
        terminals = ["the", "a", "cat", "dog", "chases", "sees"]

        productions = Dict(
            "S" => [["NP", "VP"]],
            "NP" => [["Det", "Noun"]],
            "VP" => [["Verb", "NP"]],
            "Det" => [["the"], ["a"]],
            "Noun" => [["cat"], ["dog"]],
            "Verb" => [["chases"], ["sees"]]
        )

        start_symbol = "S"

        return CFG(nonterminals, terminals, productions, start_symbol)
    end

    # Recursive string generation function
    function generate_string(
        cfg::CFG,
        symbol::String,
        current_depth::Int,
        max_depth::Int,
        recursion_counter::Dict{String, Int},
        max_recursion::Int
    )
        # If the symbol is a terminal, simply return it
        if symbol in cfg.terminals
            return symbol

        # If we have reached the maximum allowed depth, return an empty string to avoid complexity explosion
        elseif current_depth >= max_depth
            return ""
        else
            # Retrieve possible productions for the current non-terminal
            possible_productions = cfg.productions[symbol]

            # Select one production at random to introduce variety
            chosen_production = rand(possible_productions)

            result_string = ""
            for sub_symbol in chosen_production
                # If we encounter the same symbol again, check recursion depth
                if sub_symbol == symbol
                    if recursion_counter[symbol] >= max_recursion
                        # If recursion exceeds max limit, skip this branch
                        continue
                    else
                        recursion_counter[symbol] += 1
                    end
                end

                # Recursively generate a substring
                substring = generate_string(cfg, sub_symbol, current_depth + 1, max_depth, recursion_counter, max_recursion)
                # Concatenate substrings with a space
                result_string = result_string * " " * substring
            end

            return result_string
        end
    end

    """
        complexity_to_params(complexity_level::Int)

        Given a single integer complexity level, return a tuple `(max_depth, max_length, max_recursion)` 
        derived from this complexity parameter. The mapping can be adjusted as needed.

        Parameters:
        - `complexity_level::Int`: A positive integer representing the complexity level.

        Returns:
        - A tuple `(max_depth::Int, max_length::Int, max_recursion::Int)`.

        Example:
        ```julia
        julia> complexity_to_params(1)
        (2, 7, 1)
    """
    function complexity_to_params(complexity_level::Int)
        # Example mapping (adjust as desired): 
        # Increase max_depth linearly with complexity_level 
        max_depth = 1 + complexity_level
        # Increase max_length a bit faster than complexity_level
        max_length = 5 + complexity_level * 2 
        # Increase max_recursion slowly as complexity grows
        max_recursion = ceil(Int, complexity_level / 2)
        return (max_depth, max_length, max_recursion) 
    end

    """
        generate_dataset(number_of_strings::Int, max_depth::Int, max_length::Int, max_recursion::Int)

        Generate a dataset of strings from the given context-free grammar (cfg) by explicitly specifying the complexity parameters. This variant of generate_dataset is for users who desire fine-grained control over complexity.
        
        Parameters
            number_of_strings::Int: The number of strings to generate.
            max_depth::Int: The maximum allowable derivation depth, controlling how "deep" the expansions can go.
            max_length::Int: The maximum allowable number of tokens (words) in each generated string.
            max_recursion::Int: The maximum number of recursive expansions allowed for any single non-terminal symbol.

        Returns

            A Vector{String} containing the generated dataset of strings that conform to the specified complexity constraints.

        Example

        julia> dataset = generate_dataset(10, 5, 10, 2)
        10-element Vector{String}:
        "a cat sees the cat"
        "the dog sees a dog"
        "a cat sees the dog"
        ...
    """
    function generate_dataset(
        number_of_strings::Int,
        max_depth::Int,
        max_length::Int,
        max_recursion::Int
    )
        generated_strings = String[]

        cfg = create_cfg()

        for _ in 1:number_of_strings
            # Initialize recursion counters for each nonterminal
            recursion_counter = Dict{String, Int}(nt => 0 for nt in cfg.nonterminals)

            # Generate a string from the start symbol
            str = generate_string(cfg, cfg.start_symbol, 0, max_depth, recursion_counter, max_recursion)
            str = strip(str)

            # Check if the generated string meets the maximum length requirement (by word count)
            if 0 < length(split(str)) <= max_length
                push!(generated_strings, str)
            end
        end

        return generated_strings
    end

    """ 
        generate_dataset(number_of_strings::Int, complexity_level::Int)

        Generate a dataset of strings from the given context-free grammar (cfg) using a single complexity parameter. This is a user-friendly approach where you provide just one number (complexity_level) rather than setting max_depth, max_length, and max_recursion individually. Internally, complexity_to_params is used to determine these parameters.
        Parameters

            number_of_strings::Int: The number of strings to generate.
            complexity_level::Int: An integer that controls the overall complexity. Increasing this value typically increases sentence length, recursive structure, and derivation depth in a controlled manner.

        Returns

            A Vector{String} containing the generated dataset of strings corresponding to the given complexity level.

        Example

        julia> dataset = generate_dataset(10, 3) # complexity level 3
        10-element Vector{String}:
        "the dog sees a cat"
        "a cat chases the dog"
        "a dog sees a dog"
        ...
    """
    function generate_dataset(
        number_of_strings::Int,
        complexity_level::Int
    )
        max_depth, max_length, max_recursion = complexity_to_params(complexity_level)
        return generate_dataset( number_of_strings, max_depth, max_length, max_recursion )
    end



end  # module BenchmarkDataNLP
