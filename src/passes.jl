
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

# hyphen between 2 chars to disc
function discretize_hyphen(two_nl)
    inner = Classes.SEQ([Classes.ELE([Classes.ID("disc")]),
        Classes.ELE([Classes.CHAR("-")]),
        Classes.ELE([]),
        Classes.ELE([Classes.CHAR("-")])])
    return [two_nl[1]; inner; two_nl[3]]
end
hyphen_pattern = [Classes.CHAR(r"[^\-]"),
    Classes.CHAR(r"[-]"), Classes.CHAR(r"[^\-]")]

hyphen_disc_pass = Pass(hyphen_pattern,
    discretize_hyphen)
push!(processed_passes, hyphen_disc_pass)

adjacent_cjk_pattern = [Classes.CHAR(r"[\p{Han}]"),
    Classes.CHAR(r"[\p{Han}]")]

# in latin+cjk and latin+cjk add glue.
function insert_hglue_in_adjacent_cjk_lat(two_nl)
    inner = Classes.ID("cjk_lat_spacing")
    return [two_nl[1]; inner; two_nl[2]]
end
adjacent_cjk_lat_pattern = [Classes.CHAR(r"[\p{Han}]"),
    Classes.CHAR(r"[^\p{Han}·，。！？：」』》】］〕』〗〉｝…—「『《〔［【『〖〈｛]")]
adjacent_cjk_lat_pattern2 = [Classes.CHAR(r"[^\p{Han}·，。！？：」』》】］〕』〗〉｝…—「『《〔［【『〖〈｛]"),
    Classes.CHAR(r"[\p{Han}]")]

adjacent_cjk_lat_pass = Pass(adjacent_cjk_lat_pattern,
    insert_hglue_in_adjacent_cjk_lat)
push!(processed_passes, adjacent_cjk_lat_pass)

adjacent_cjk_lat2_pass = Pass(adjacent_cjk_lat_pattern2,
    insert_hglue_in_adjacent_cjk_lat)
push!(processed_passes, adjacent_cjk_lat2_pass)

# in 2 hanzi add glue.
function insert_hglue_in_adjacent_cjk(two_nl)
    inner = Classes.ID("cjk_spacing")
    return [two_nl[1]; inner; two_nl[2]]
end
adjacent_cjk_pattern = [Classes.CHAR(r"[\p{Han}]"),
    Classes.CHAR(r"[\p{Han}]")]

adjacent_cjk_pass = Pass(adjacent_cjk_pattern,
insert_hglue_in_adjacent_cjk)
push!(processed_passes, adjacent_cjk_pass)

# line breaking rule in CJK 避頭尾/禁則処理
adjacent_cjk_punc_pattern = [Classes.CHAR(r"[·，。！？：」』》】］〕』〗〉｝]"),
    Classes.CHAR(r"[^·，。！？：」』》】］〕』〗〉｝]")]

adjacent_cjk_punc_pattern2 = [Classes.CHAR(r"[^「『《〔［【『〖〈｛]"),
    Classes.CHAR(r"[「『《〔［【『〖〈｛]")]
adjacent_cjk_punc_pattern3 = [Classes.CHAR(r"[…—]"),
    Classes.CHAR(r"[^…—]")]

adjacent_glue_pass = Pass(adjacent_cjk_pattern,
insert_hglue_in_adjacent_cjk)
push!(processed_passes, adjacent_glue_pass)

adjacent_glue_pass2 = Pass(adjacent_cjk_punc_pattern2,
insert_hglue_in_adjacent_cjk)
push!(processed_passes, adjacent_glue_pass2)

adjacent_glue_pass3 = Pass(adjacent_cjk_punc_pattern3,
insert_hglue_in_adjacent_cjk)
push!(processed_passes, adjacent_glue_pass3)


end