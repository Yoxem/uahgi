
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

end