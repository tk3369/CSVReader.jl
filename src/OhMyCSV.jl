module OhMyCSV

using DataFrames: DataFrame
using InternedStrings
using Parsers

# Parsers
parse_string(s::AbstractString) = intern(s)
parser_return_type(::Val{parse_string}) = AbstractString

parse_float64(s::AbstractString) = something(Parsers.tryparse(s, Float64), Missing)
parser_return_type(::Val{parse_float64}) = Union{Float64, Missing}

# Int parser handles float values in case of surprises
parse_int(s::AbstractString) = let s = intern(s) 
    something(Parsers.tryparse(s, Int), Parsers.tryparse(s, Float64), Missing)
end
parser_return_type(::Val{parse_int}) = Union{Int, Float64, Missing}

function read_csv(filename; headers = true, delimiter = ",", quotechar = '"', nrows = 0)
    parsers = infer_parsers(filename, headers, delimiter, quotechar)
    read_csv_with_parsers(filename, parsers, headers = headers, delimiter = delimiter, nrows = nrows)
end

function read_csv_with_parsers(filename, parsers; headers = true, delimiter = ",", nrows = 0)  
    open(filename) do f
        hdr = read_headers(f, headers, delimiter)
        lines = nrows == 0 ? [] : Vector(undef, nrows)
        r = 0
        while !eof(f)
            line = readline(f)
            row = map(x -> x[1](x[2]), zip(parsers, split(line, delimiter)))
            r += 1
            nrows == 0 ? push!(lines, row) : lines[r] = row
        end
        c = length(hdr)
        n = length(lines)
        #DataFrame([[L[j] for L in lines] for j in 1:c], Symbol.(hdr))
        lines
    end
end

function read_headers(f, with_headers, delimiter)
    if with_headers
        split(readline(f), delimiter)
    else
        ["_$i" for i in 1:c]
    end
end

function infer_parsers(filename, headers, delimiter, quotechar)
    sample_lines = get_sample_lines(filename, headers = headers)
    for line in sample_lines
        cells = strip.(split(line, delimiter), quotechar)
        return infer_parser.(cells)  # TODO look beyond first line
    end
end

# infer parser needed from a string
function infer_parser(s)
    if match(r"^\d+\.\d*$", s) != nothing ||      # covers 12.
            match(r"^\d*\.\d+$", s)!= nothing     # covers .12
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
    #println(few_lines)
    if length(few_lines) > 0
        sum(length, few_lines) ÷ length(few_lines)
    else
        0
    end
end

function read_first_few_lines(f, lines_to_read)
    lines = []
    count = 0
    while !eof(f) && count < lines_to_read
        line = readline(f)
#        @show line
        push!(lines, line)
        count += 1
    end
    lines
end

end # module

