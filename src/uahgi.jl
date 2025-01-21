module uahgi
include("./parsing.jl")
using .Parsing
using ArgParse

function parse_commandline()
    #= please see:
    https://carlobaldassi.github.io/ArgParse.jl/stable/
    =#
    s = ArgParseSettings()

    @add_arg_table! s begin
        "FILE"
            help = "the file path to be converted."
            required = true
    end

    return parse_args(s)
end


function main()
    parsed_args = parse_commandline()
    file_path = parsed_args["FILE"]
    file_content = open(f->read(f, String), file_path)
    Parsing.parse(file_content)
end

main()
end

