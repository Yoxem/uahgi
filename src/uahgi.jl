module uahgi
include("parsing.jl")
include("interp.jl")
include("arrange.jl")
include("pdfoperating.jl")

using .Interp
using .Parsing
using .Arrange
using .PDFOperating
using ArgParse

export ChBox, HGlue
abstract type Box end

"""
a like-breakable discrete point.
- before: the item before likebreaking
- after: the item after linebreaking
- orig: the status while not triggering like breaking
"""
mutable struct Disc<:Box
    before
    after
    orig
end

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
    x
    y
end

"""
Horizonal Glue (HGlue)
- wd : width
- stretch : stretch
"""
mutable struct HGlue<:Box
    wd
    stretch
end

"""
Par
- for paragraph marker.
"""
mutable struct Par<:Box
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
    x
    y
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
    x
    y
end

function parse_commandline()
    #= please see:
    https://carlobaldassi.github.io/ArgParse.jl/stable/
    =#
    s = ArgParseSettings()

    @add_arg_table! s begin
        "FILE"
            help = "the file path to be converted."
            required = false
    end

    return parse_args(s)
end


function main()
    parsed_args = parse_commandline()
    file_path = parsed_args["FILE"]
    if file_path === nothing
    #help string
    help = "usage: uahgi.jl [-h] [FILE]

    positional arguments:
      FILE        the file path to be converted.
    
    optional arguments:
      -h, --help  show this help message and exit"
        println(help)
        return 0
    end
    # for test
    #if parsed_args["FILE"] === nothing
    #    file_path = "./example/ex1.ug"
    #else
    #    file_path = parsed_args["FILE"]
    #end
    file_content = open(f->read(f, String), file_path)
    ast = Parsing.parse(file_content)


    default_env = Dict() # the default environment for the intepreter
    output_box_orig = VBox([HBox([], nothing, nothing, nothing, nothing, nothing)],
                          nothing, nothing, nothing, nothing, nothing)
    output_box_result = Interp.interp_main(ast, default_env, output_box_orig)
    env = output_box_result[2]
    output_box =  output_box_result[3]
    arranged = Arrange.arrange(output_box, env)
    unit_positioned = Arrange.position(arranged, env)
    generated_pdf = PDFOperating.generate_pdf(unit_positioned, file_path[1:end-3] * ".pdf")
end

main()
end

