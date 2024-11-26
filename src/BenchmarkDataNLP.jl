module BenchmarkDataNLP

    export greet, add_random_suffix, repeat_string

    using Random

    """
        greet()

    Prints a friendly greeting message to the console.

    Returns nothing
    """
    greet() = println("Hello World! Yours Truly, B.D.NLP")

    """
        add_random_suffix(input::AbstractString) -> String

    Takes a string and returns it with a random 5-character suffix added.

    Returns a string

    # Examples

        julia> add_random_suffix("hello")
        "helloabc12"
    """
    function add_random_suffix(input::AbstractString)
        random_suffix = randstring(5)
        return input * random_suffix
    end

    """
        repeat_string(input::AbstractString, times::Int) -> String

    Repeats a string or character a specified number of times.

    Returns a string
    
    # Examples

        julia> repeat_string("hi", 3)
        "hihihi"
    """
    function repeat_string(input::AbstractString, times::Int)
        return repeat(input, times)
    end

end  # module BenchmarkDataNLP
