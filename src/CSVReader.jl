module CSVReader

using DataFrames: DataFrame, AbstractDataFrame, nrow
using InternedStrings
using Parsers

export @parsers_str

# Parsers addition to support AbstractString
# See https://github.com/JuliaData/Parsers.jl/issues/6
function mytryparse(str::AbstractString, ::Type{T}; kwargs...) where {T}
    res = Parsers.parse(Parsers.defaultparser, IOBuffer(str), T; kwargs...)
    return Parsers.ok(res.code) ? res.result : nothing
end

# Parsers
parse_string(s) = intern(s)
parser_return_type(::Val{parse_string}) = Union{String, Missing}

parse_float64(s::AbstractString) = something(mytryparse(s, Float64), missing)
parser_return_type(::Val{parse_float64}) = Union{Float64, Missing}

parse_int(s) = something(mytryparse(s, Int), missing)
parser_return_type(::Val{parse_int}) = Union{Int, Missing}

"""
Construct parsers from a parser spec string.  The string contains a
comman separated value of the format <parser>:<length>.  For example,
s:10,f:2,i:5 means 10 strings, 2 floats, and 5 int's.
"""
macro parsers_str(s) 
    parser_dict = Dict("i" => parse_int, "f" => parse_float64, "s" => parse_string)
    sep = ':'
    parsers = []
    for spec in mysplit(s)
        if occursin(sep, spec)
            T, L = mysplit(spec, delimiter = sep)     # f:10 => means 10 floats
            N = mytryparse(L, Int)
            !haskey(parser_dict, T) && error("Invalid parser spec: $spec (unknown parser '$T')")
            (N == nothing || N <= 0) && error("Invalid parser spec: $spec (bad length '$N')")
            parsers = vcat(parsers, fill(parser_dict[T], N))
        else
            T = spec
            !haskey(parser_dict, T) && error("Invalid parser spec: $spec (unknown parser)")
            push!(parsers, parser_dict[T])
        end
    end
    parsers
end

"""
Read CSV file
"""
function read_csv(filename; headers = true, delimiter = ',', quotechar = '"')
    parsers = infer_parsers(filename, headers, delimiter, quotechar)
    read_csv(filename, parsers, headers = headers, delimiter = delimiter)
end

"""
Read CSV file with user specified parsers
"""
function read_csv(filename, parsers; headers = true, delimiter = ',', quotechar = '"')  
    est_lines = estimate_lines_in_file(filename, with_headers = headers)
    open(filename) do f
        hdr = read_headers(f, headers, delimiter)
        r = 0
        preallocate_rows = est_lines
        df = make_dataframe(hdr, parser_return_type.(Val.(parsers)), preallocate_rows)
        while !eof(f)
            line = readline(f)
            r += 1
            if r > preallocate_rows
                new_size = max(floor(Int, preallocate_rows * 1.05 + 5), preallocate_rows + 5)
                @debug "Growing data frame from $preallocate_rows rows to $new_size"
                grow_dataframe!(df, new_size)
                preallocate_rows = new_size
            end 
            parse_line!(df, r, parsers, line, delimiter, quotechar)
        end
        trim_table(df, r)
    end
end

"""
Peek into first few lines of CSV file
"""
function peek_csv(filename; headers = true, nrows = 5, delimiter = ',')
    open(filename) do f
        headers = read_headers(f, headers, delimiter)
        rows = read_first_few_lines(f, nrows)
        ncols = maximum(length(x) for x in [mysplit(row, delimiter = delimiter) for row in rows])
        @info "Peeking into first few rows => there are $ncols columns" rows
    end
    nothing
end

# Warning: type piracy!
function grow_dataframe!(df::AbstractDataFrame, rows::Integer)
    rows <= nrow(df) && error("Current data frame has $(nrow(df)) rows but you specified to grow to $rows rows!")
    for c in names(df)
        df[c] = resize!(df[c], rows)
    end
    nothing
end

function parse_line!(df, row, parsers, line, delimiter, quotechar)
    strings = mysplit(line, delimiter = delimiter, quotechar = quotechar)
    for (i, p) ∈ enumerate(parsers)
        parsed_value = p(strings[i])
        #@debug "Parsed line" row i parsed_value
        df[row,i] = parsed_value
    end
    nothing
end

# Make a new DataFrame
function make_dataframe(hdr, types, rows)
    # @info "Making table with $rows rows"
    # @info "Types = $types"
    # @info "Types[11] = $(types[11])"
    hdr = something(hdr, ["_$i" for i ∈ 1:length(types)])
    cols = [Vector{T}(undef, rows) for T in types]
    df = DataFrame(cols, Symbol.(hdr), makeunique = true)
    #@show df
    df
end

function trim_table(df, rows)
    @debug "Trimming table" nrow(df) rows
    df[1:rows, :]
end

function read_headers(f, headers, delimiter)
    if headers
        mysplit(readline(f), delimiter = delimiter)
    else
        nothing
    end
end

function infer_parsers(filename, headers, delimiter, quotechar)
    open(filename) do f
        headers && readline(f)
        first_line = readline(f)
        cells = mysplit(first_line, delimiter = delimiter, quotechar = quotechar)
        infer_parser.(cells) 
    end
end

function infer_parsers_old(filename, headers, delimiter, quotechar)
    sample_lines = get_sample_lines(filename, headers = headers)
    for line in sample_lines
        cells = mysplit(line, delimiter = delimiter, quotechar = quotechar)
        return infer_parser.(cells)  # TODO look beyond first line
    end
end

# infer parser needed from a string
function infer_parser(s)
    if match(r"^\d+\.\d*$", s) != nothing ||      # covers 12.
            match(r"^\d*\.\d+$", s)!= nothing ||  # covers .12
            match(r"^\d+\.\d*e[+-]\d$", s) != nothing
        parse_float64
    elseif match(r"^\d+$", s) != nothing          # covers 123
        parse_int
    else
        parse_string
    end
end

# get some sample lines
function get_sample_lines(filename; headers = true, max_reach_pct = 0.1, samples_pct = 0.1, max_samples = 10)
    L = estimate_lines_in_file(filename)
    L_upper = floor(Int, L * max_reach_pct)   # don't read lines further than this
    L_lower = headers ? 2 : 1
    num_samples = min(max_samples, floor(Int, L_upper * samples_pct))
    @info "There are approximately $L lines in the file"
    @info "Taking at most $(num_samples) samples between L$(L_lower) and L$(L_upper)"
    samples = unique(sort(rand(L_lower:L_upper, num_samples)))
    n = 1
    i = 1
    lines = String[]
    open(filename) do f
        while !eof(f)
            line = readline(f)
            if n == samples[i]   # take sample
                push!(lines, line)
                i += 1
                i > length(samples) && break
            end
            n += 1
        end
    end
    lines
end

function estimate_lines_in_file(filename; line_length_samples = 10, with_headers = true)
    s = filesize(filename)
    open(filename) do f
        with_headers && readline(f)  # skip header
        L =  estimate_line_length(f, line_length_samples)
        L > 0 ? s ÷ L : 0
    end
end

function estimate_line_length(f, line_length_samples)
    few_lines = read_first_few_lines(f, line_length_samples)
    if length(few_lines) > 0
        sum(length, few_lines) ÷ length(few_lines)
    else
        0
    end
end

function read_first_few_lines(f, lines_to_read)
    lines = String[]
    count = 0
    while !eof(f) && count < lines_to_read
        line = readline(f)
        push!(lines, line)
        count += 1
    end
    lines
end

function mysplit(str::AbstractString; delimiter::AbstractChar = ',', quotechar::AbstractChar = '"', strip_quotes = true)
    within_quote = false
    last_index = 1
    values = String[]
    for (i, c) in enumerate(str)
        if c == quotechar && !within_quote
            within_quote = true
            continue
        end
        if c == quotechar && within_quote
            within_quote = false
            continue
        end
        if c == delimiter && !within_quote
            push!(values, str[last_index:i-1])
            last_index = i + 1
        end
    end
    if last_index <= length(str) || str[end] == delimiter
        push!(values, str[last_index:end])
    end
    strip_quotes ? [strip(x, [quotechar, ' ']) for x in values] : values
end

end # module

