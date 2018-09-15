module OhMyCSV

using DataFrames: DataFrame

parse_float64(s::AbstractString) = length(s) == 0 ? Missing : parse(Float64, s)
parser_return_type(::Val{parse_float64}) = Union{Float64, Missing}

parse_float64_nan(s::AbstractString) = length(s) == 0 ? NaN : parse(Float64, s)
parser_return_type(::Val{parse_float64_nan}) = Float64

parse_string(s::AbstractString) = s
parser_return_type(::Val{parse_string}) = AbstractString

"""
Read CSV file
"""
function read(filename, parsers)
    (headers, lines) = read_file(filename)
    
    # pre-allocate column arrays
    rows = length(lines)
    types = parser_return_type.(Val.(parsers))
    data = [Vector{T}(undef, rows) for T ∈ types]
    
    # loop
    row = 1
    #println("There are ", length(lines), " lines")
    for line in lines
        j = firstindex(line)
        col = 1
        @inbounds for (i,c) ∈ enumerate(line)
            if c == ','
                cell = strip(line[j:i-1], '"')
                data[col][row] = parsers[col](cell)
                j = i+1   # reset last index
                col += 1
            end
        end
        if j < lastindex(line)
            cell = strip(line[j:end], '"')
            data[col][row] = parsers[col](cell)
        end
        row += 1
    end
    DataFrame(data, headers)
end

# read whole file into memory
function read_file(filename)
    lines = String[]
    open(filename) do f
        global hdr = Symbol.(split(readline(f), ","))
        while !eof(f)
            push!(lines, readline(f))
        end
    end
    (headers=hdr, lines=lines)
end


end # module
