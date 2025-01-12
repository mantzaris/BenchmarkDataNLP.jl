

function sample_alphabet(complexity::Int,alphabet_unicode_start_ind::Int,min_alphabet_size::Int,alphabet_size_complexity_100::Int)
    char_number = round(Int, linear_extrapolate(complexity, min_alphabet_size, alphabet_size_complexity_100; cmin=1, cmid=100))
    return Char.( alphabet_unicode_start_ind:alphabet_unicode_start_ind+char_number-1 )
end

function sample_punctuation(complexity::Int,punctuation_unicode_start_ind::Int,min_punctuation_size::Int,punctuation_size_complexity_100::Int)
    char_number = round(Int, linear_extrapolate(complexity, min_punctuation_size, punctuation_size_complexity_100; cmin=1, cmid=100))
    
    punctuation_chars = punctuation_unicode_start_ind : punctuation_unicode_start_ind + char_number - 1
    punctuation_strings = String[]
    for code in punctuation_chars
        c = Char(code) #eg Char(256) => 'Ā'
        push!(punctuation_strings, string(c)) #eg string('Ā') => "Ā"
    end

    return punctuation_strings
    # return Char.( punctuation_unicode_start_ind:punctuation_unicode_start_ind+char_number-1 )
end

function sample_vocabulary(complexity::Int, 
                            alphabet::Vector{Char},
                            min_vocabulary_size::Int,
                            vocabulary_size_complexity_100::Int,
                            min_word_size::Int,
                            word_size_complexity_100::Int)::Vector{String}
    vocabulary_size = round(Int, linear_extrapolate(complexity, min_vocabulary_size, vocabulary_size_complexity_100; cmin=1, cmid=100))
    max_word_size = round(Int, linear_extrapolate(complexity, min_word_size, word_size_complexity_100; cmin=1, cmid=100))

    words = Vector{String}(undef, vocabulary_size)

    # * ensure in future that words are unique
    # * distribution on word size
    for i in 1:vocabulary_size
        wlen = rand(1:max_word_size)
        # sample wlen chars from the alphabet
        wchars = rand(alphabet, wlen)
        words[i] = join(wchars)
    end

    return words
end



function linear_extrapolate(c::Int, vmin::Real, vmax::Real; 
                                cmin::Int=1, cmid::Int=100)

    if c < cmin
        error("Complexity must be >= $cmin.")
    end

    vmin = Float64(vmin)
    vmax = Float64(vmax)
    
    # slope from cmin => cmid
    slope = (vmax - vmin) / (cmid - cmin)
    return vmin + slope*(c - cmin)
end



function try_to_get_integer(variable_value)
    try
        if variable_value isa Integer
            return variable_value
        elseif variable_value isa String
            try
                return parse(Int, variable_value)
            catch
                digits_only = match(r"\d+", variable_value)
                if !isnothing(digits_only)
                    return parse(Int, digits_only.match)
                end                
                try
                    return round(Int, parse(Float64, variable_value))
                catch
                    sci_match = match(r"[-+]?\d*\.?\d+[eE][-+]?\d+", variable_value)
                    if !isnothing(sci_match)
                        return round(Int, parse(Float64, sci_match.match))
                    end
                end
            end
        elseif variable_value isa Rational
            return round(Int, float(variable_value))
        elseif variable_value isa AbstractFloat
            return round(Int, variable_value)
        elseif variable_value isa AbstractArray && length(variable_value) > 0
            # For arrays, try to get first numeric element
            for element in variable_value
                result = try_to_get_integer(element)
                if !isnothing(result)
                    return result
                end
            end
        end
    catch
    end
    return nothing
end


