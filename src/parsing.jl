module Parsing
using ParserCombinator
using Match

include("passes.jl")
using .Passes

#=
grammar rules of uahgi
=#

comment = P"\%[^%]+\%"
newline = P"(\r?\n)" |> Passes.Classes.NL
space = p"[ \t]" > Passes.Classes.SPACE

id_name = p"[_a-zA-Z][_0-9a-zA-Z]*" > Passes.Classes.ID
id = E"@" + id_name

char = p"[^ \n\r\t\\]" > Passes.Classes.CHAR #[1:2,:?]

# chars should be preceded by "\" are \, {, }, |, @, %
esc_char = p"[\{\|\}\@\%]" > Passes.Classes.ESC_CHAR
esc_combined = E"\\" + esc_char
#=
seq = (foo x1 x2 " ")
=> {@foo|x1|x2| }
=#
char_and_combined = char | esc_combined
seq_item = id | Repeat(char_and_combined) |> Passes.Classes.ELE
seq_item_rest = E"|" + seq_item
seq_inner = seq_item + (seq_item_rest)[0:end] |> Passes.Classes.SEQ
seq = E"{" + seq_inner + E"}"


part =  seq | comment | space | newline | id | char
all = (Repeat(part) + Eos()) |> Passes.Classes.PROG

function parse(input)
    print(input)
    ast = parse_one(input, all)[1]
    print("\n" * string(ast) * "\n")
    
    
    #print(parse_one(, Pattern(r".b.")))
    
    passes = Passes.processed_passes


    ast_val = ast.val
    for pass in passes
        ast_val = use_pass(ast_val, pass)
    end

    new_ast = Passes.Classes.PROG(ast_val)
    print(ast_to_string(new_ast))
    return ast
end


function ast_pattern_matched(pattern, ast_head)
    zipped = zip(pattern, ast_head)
    zipped_mapped = map(x -> match_unit(x), zipped)
    is_all_matched = reduce((x,y)-> x && y, zipped_mapped)
    return is_all_matched
end

function match_unit(pair)
    pattern = pair[1]
    ast_item = pair[2]
    #println(pattern, "~~~", ast_item)
    if typeof(pattern) != typeof(ast_item)
        return false
    elseif typeof(pattern.val) == Regex
        is_matched = occursin(pattern.val, ast_item.val)
        return is_matched
    else
        return pattern.val == ast_item.val
    end
end

function use_pass(ast_val, pass)
    pass_pattern = pass.pattern
    pass_pattern_length = length(pass_pattern)
    if length(ast_val) < pass_pattern_length
        return ast_val
    else
        ast_head = ast_val[1:pass_pattern_length]

        if ast_pattern_matched(pass_pattern, ast_head)          
            ast_head = pass.func(ast_head)
            raw_remained = [ast_head[2:end];ast_val[pass_pattern_length+1:end]]
            remained = use_pass(raw_remained, pass)
            ast_val = [ast_head[1]; remained]
        else
            raw_remained = ast_val[2:end]
            remained = use_pass(raw_remained, pass)
            ast_val = [ast_head[1]; remained]
            return ast_val
        end
    end
end

function ast_to_string(ast)
    item = 5
    str = @match ast begin
        Passes.Classes.PROG(v) => begin
                    prog_inner = reduce( (x, y) -> x*" "*y, map(i -> ast_to_string(i), v))
                    return "[" * prog_inner * "]"
                end
        Passes.Classes.SEQ(v) => begin
                    prog_inner = reduce( (x, y) -> x*" "*y, map(i -> ast_to_string(i), v))
                    return "(" * prog_inner * ")"
                end
        Passes.Classes.ID(v) => "[ID: " * v * "]"
        Passes.Classes.ELE(v) => begin
            prog_inner = reduce( (x, y) -> x*" "*y, map(i -> ast_to_string(i), v))
            return "[ELE : (" * prog_inner * ")]"
            end
        Passes.Classes.ESC_CHAR(ch) => "[ESC:\"" * ch[1] * "\"]"
        Passes.Classes.CHAR(ch) => "\"" * ch[1] *  "\""
        Passes.Classes.NL(_) => "NL"
        Passes.Classes.SPACE(_) => "SPACE"


        _ => string(ast)
    end
    return str
end

# Write your package code here.
#export cat

#cat = 1.2


end