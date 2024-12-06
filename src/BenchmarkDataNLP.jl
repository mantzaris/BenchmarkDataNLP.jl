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

    # Global Terminal Dictionaries:
    # Here we store all possible terminals for each category.
    const ALL_TERMINALS = Dict(
        "Det" => ["the", "a", "every", "some", "no", "this", "that"],
        "Noun" => ["cat", "dog", "horse", "elephant", "lion", "giraffe"],
        "Verb" => ["chases", "sees", "admires", "devours", "observes", "questions"],
        "Adjective" => ["furry", "angry", "tiny", "massive", "quick", "lazy"],
        "Preposition" => ["in", "on", "under", "over", "near", "beside"]
    )

    # Global Terminal Dictionaries:
    # Here we store all possible terminals for each category.
    const ALL_TERMINALS = Dict(
        "Det" => ["the", "a", "every", "some", "no", "this", "that"],
        "Noun" => ["cat", "dog", "horse", "elephant", "lion", "giraffe"],
        "Verb" => ["chases", "sees", "admires", "devours", "observes", "questions"],
        "Adjective" => ["furry", "angry", "tiny", "massive", "quick", "lazy"],
        "Preposition" => ["in", "on", "under", "over", "near", "beside"]
    )

    # Global Productions Dictionary:
    # Each key is a nonterminal. The value is a vector of tuples (min_complexity, production_vector).
    # min_complexity: The minimum complexity level at which this production becomes available.
    const ALL_PRODUCTIONS = Dict{String, Vector{Tuple{Int, Vector{String}}}}(
        "S" => [(1, ["NP", "VP"])],
        "NP" => [
            (1, ["Det", "Noun"]),
            (3, ["Det", "AdjP", "Noun"]),
            (4, ["Det", "Noun", "PP"]),
            (5, ["Det", "AdjP", "Noun", "PP"])
        ],
        "VP" => [
            (1, ["Verb", "NP"])
        ],
        "AdjP" => [
            (3, ["Adjective"]),
            (4, ["Adjective", "AdjP"])
        ],
        "PP" => [
            (4, ["Preposition", "NP"])
        ],
        "Det" => [],
        "Noun" => [],
        "Verb" => [],
        "Adjective" => [],
        "Preposition" => []
    )
    
    

    # We can create a mapping from complexity level to how many terminals of each type we pick.
    function complexity_to_counts(complexity_level::Int)
        # For example: scale nouns, verbs, and determiners linearly.
        noun_count = min(length(ALL_TERMINALS["Noun"]), 2 + complexity_level)
        verb_count = min(length(ALL_TERMINALS["Verb"]), 2 + complexity_level)
        det_count  = min(length(ALL_TERMINALS["Det"]), 2 + complexity_level)
        # Adjectives and prepositions appear only if they are needed by some productions at that complexity.
        # We can simply pick some number proportional to complexity as well:
        adj_count = complexity_level # pick up to complexity_level adjectives if needed
        prep_count = complexity_level # similarly for prepositions
        return (det_count, noun_count, verb_count, adj_count, prep_count)
    end


    # Filter productions by complexity level:
    function filter_productions(all_prods::Dict{String,Vector{Tuple{Int,Vector{String}}}}, complexity_level::Int)
        filtered = Dict{String, Vector{Vector{String}}}()
        for (nt, rule_list) in all_prods
            # Include only those whose min_complexity <= complexity_level
            valid_rules = [rhs for (c_level, rhs) in rule_list if c_level <= complexity_level]
            # It's possible some categories (like lexical ones) are empty or not needed
            # If valid_rules is empty but we need that nonterminal, we just skip it or leave it empty.
            filtered[nt] = valid_rules
        end
        return filtered
    end


    # Assign terminals to their categories and fill in the lexical productions accordingly.
    function assign_terminals!(productions::Dict{String,Vector{Vector{String}}}, complexity_level::Int)
        det_count, noun_count, verb_count, adj_count, prep_count = complexity_to_counts(complexity_level)

        # Pick subsets (or all) terminals:
        chosen_dets = ALL_TERMINALS["Det"][1:min(end, det_count)]
        chosen_nouns = ALL_TERMINALS["Noun"][1:min(end, noun_count)]
        chosen_verbs = ALL_TERMINALS["Verb"][1:min(end, verb_count)]

        # Only add adjectives if AdjP rules exist at this complexity:
        chosen_adjs = []
        if haskey(productions, "AdjP") && !isempty(productions["AdjP"]) 
            chosen_adjs = ALL_TERMINALS["Adjective"][1:min(end, adj_count)]
        end

        # Only add prepositions if PP rules exist:
        chosen_preps = []
        if haskey(productions, "PP") && !isempty(productions["PP"])
            chosen_preps = ALL_TERMINALS["Preposition"][1:min(end, prep_count)]
        end

        # Update lexical categories:
        if haskey(productions, "Det")
            productions["Det"] = [[d] for d in chosen_dets]
        end
        if haskey(productions, "Noun")
            productions["Noun"] = [[n] for n in chosen_nouns]
        end
        if haskey(productions, "Verb")
            productions["Verb"] = [[v] for v in chosen_verbs]
        end
        if haskey(productions, "Adjective")
            productions["Adjective"] = [[a] for a in chosen_adjs]
        end
        if haskey(productions, "Preposition")
            productions["Preposition"] = [[p] for p in chosen_preps]
        end

        # Build the terminal list
        terminals = vcat(chosen_dets, chosen_nouns, chosen_verbs, chosen_adjs, chosen_preps)
        return terminals
    end


    function create_cfg(complexity_level::Int)
        # Filter and assign terminals based on complexity
        filtered_prods = filter_productions(ALL_PRODUCTIONS, complexity_level)
        terminals = assign_terminals!(filtered_prods, complexity_level)
    
        nonterminals = collect(keys(filtered_prods))
        start_symbol = "S"
        if !haskey(filtered_prods, start_symbol)
            error("No 'S' symbol found in productions! Check your production definitions.")
        end
    
        return CFG(nonterminals, terminals, filtered_prods, start_symbol)
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
        if symbol in cfg.terminals
            return symbol
        elseif current_depth >= max_depth
            return ""
        else
            possible_productions = cfg.productions[symbol]

            # If no productions available (empty?), return empty string
            if isempty(possible_productions)
                return ""
            end

            chosen_production = rand(possible_productions)

            result_string = ""
            for sub_symbol in chosen_production
                if sub_symbol == symbol
                    if recursion_counter[symbol] >= max_recursion
                        continue
                    else
                        recursion_counter[symbol] += 1
                    end
                end

                substring = generate_string(cfg, sub_symbol, current_depth + 1, max_depth, recursion_counter, max_recursion)
                if !isempty(substring)
                    result_string = result_string * " " * substring
                end
            end

            return strip(result_string)
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
        max_recursion::Int,
        complexity_level::Int=1
    )
        generated_strings = String[]

        cfg = create_cfg(complexity_level)

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
    function generate_dataset(number_of_strings::Int, complexity_level::Int; seed::Int=1234)
        Random.seed!(seed)
        max_depth, max_length, max_recursion = complexity_to_params(complexity_level)
        cfg = create_cfg(complexity_level)
    
        generated_strings = String[]
        for _ in 1:number_of_strings
            recursion_counter = Dict{String, Int}(nt => 0 for nt in cfg.nonterminals)
            str = generate_string(cfg, cfg.start_symbol, 0, max_depth, recursion_counter, max_recursion)
            str = strip(str)
            if 0 < length(split(str)) <= max_length
                push!(generated_strings, str)
            end
        end
        return generated_strings
    end
    



end  # module BenchmarkDataNLP
