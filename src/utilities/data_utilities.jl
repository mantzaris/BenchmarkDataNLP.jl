

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


