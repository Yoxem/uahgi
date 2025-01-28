module uahgi
include("parsing.jl")
include("interp.jl")
using .Interp
using .Parsing
using ArgParse

abstract type Box end
"""
Horizonal Box

- eles = array in the Hbox
- ht = height
- dp = depth
- wd = width
"""
mutable struct HBox<:Box
    eles
    ht
    dp
    wd
end

"""
Vertical Box

- eles = array in the Hbox
- ht = height
- dp = depth
- wd = width
"""
mutable struct VBox<:Box
    eles
    ht
    dp
    wd
end

"""
Character Box

- char: character 
- font_path: font path for the char
- size: font sizein pt
- ht = height
- dp = depth
- wd = width
"""
mutable struct ChBox<:Box
    char
    font_path
    size
    ht
    dp
    wd
end

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
    # for test
    #if parsed_args["FILE"] === nothing
    #    file_path = "./example/ex1.ug"
    #else
    #    file_path = parsed_args["FILE"]
    #end
    file_content = open(f->read(f, String), file_path)
    ast = Parsing.parse(file_content)


    default_env = Dict() # the default environment for the intepreter
    output_box_orig = VBox([HBox([], nothing, nothing, nothing)],
                          nothing, nothing, nothing)
    output_box_result = Interp.interp_main(ast, default_env, output_box_orig)
    print("Env", output_box_result[2])
    print("OutPutBox", output_box_result[3])

end

main()
end

