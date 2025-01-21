module Parsing
using ParserCombinator
abstract type Node end
struct ID<:Node val end
struct SEQ<:Node val end # like (a b c) in scheme
struct ELE<:Node val end #an element in a seq
struct ESC_CHAR<:Node val end # character preceded by escape char "\"

#=
grammar rules of uahgi
=#

comment = p"\%[^%]+\%"
newline = p"(\r?\n)"
space = p"[ \t]"

id_name = p"[_a-zA-Z][_0-9a-zA-Z]*" > ID
id = E"@" + id_name

char = p"[^ \n\r\t\\]"#[1:2,:?]

# chars should be preceded by "\" are \, {, }, |, @, %
esc_char = p"[\{\|\}\@\%]" > ESC_CHAR
esc_combined = E"\\" + esc_char
#=
seq = (foo x1 x2 " ")
=> {@foo|x1|x2| }
=#
char_and_combined = char | esc_combined
seq_item = id | Repeat(char_and_combined) |> ELE
seq_item_rest = E"|" + seq_item
seq_inner = seq_item + (seq_item_rest)[0:end] |> SEQ
seq = E"{" + seq_inner + E"}"


part =  seq | comment | space | newline | id | char
all = Repeat(part) + Eos()

function parse(input)
    print(input)
    b = parse_one(input, all)
    print("\n" * string(b) * "\n")
    
    #print(parse_one(, Pattern(r".b.")))
end
# Write your package code here.
#export dog

#dog = 1.2


end