
module Passes
include("classes.jl")
using .Classes

export processed_passes, Pass
processed_passes = []

struct Pass
    pattern
    func
end

####definition of passes ####

# 2 newline become @par{}
function two_nl_to_par_pass_func(two_nl)
    return [Classes.SEQ([Classes.ID("par")])]
end

two_nl_to_par_pattern = [Classes.NL([]), Classes.NL([])] #two continuous newline

two_nl_to_par_pass = Pass(two_nl_to_par_pattern,
    two_nl_to_par_pass_func)
push!(processed_passes, two_nl_to_par_pass)

# in 2 hanzi add glue.
function insert_hglue_in_adjacent_chinese(two_nl)
    _0pt = Classes.SEQ([Classes.ID("pt"); Classes.CHAR(["0"])])
    inner = Classes.SEQ([Classes.ID("hglue"); _0pt])
    return [two_nl[1]; inner; two_nl[2]]
end
adjacent_chinese_pattern = [Classes.CHAR(r"[\p{Han}，。！？：「」『』…]"),
    Classes.CHAR(r"[\p{Han}，。！？：「」『』…]")]

adjacent_glue_pass = Pass(adjacent_chinese_pattern,
insert_hglue_in_adjacent_chinese)
push!(processed_passes, adjacent_glue_pass)

end