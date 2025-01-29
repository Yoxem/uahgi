module Interp
using Match
using Fontconfig

include("pdfoperating.jl")
using .PDFOperating

u = Main.uahgi
c = Main.uahgi.Parsing.Passes.Classes

function interp_main(ast, env, res_box)
    ast_inner = ast.val
    val = nothing
    for e in ast_inner
        (val, env, res_box) = interp(e, env, res_box)
    end
    return (val, env, res_box)
end
"""
interp: the intepreter of the uahgi.

- ast: element or part of the ast
- env: the variable storaging environment 
- res_box: the generated result box containing the content\
- put_char(bool. value): if the character should be put into the res_box
"""
function interp(ast, env, res_box, put_char=true)
    #println("INTERP", ast)
    @match ast begin
        c.SEQ([c.ELE([c.ID("def")]),
            c.ELE([c.ID(id)]),val]) => 
                        begin
                            (val_evaled, env, res_box) = interp(val, env, res_box, false)
                            #println("ID~~~", id, " VAL~~~", val_evaled)
                            env[id] = val_evaled
                            return (val_evaled, env, res_box)
                        end
        c.SEQ([c.ELE([c.ID("quote")]),
            y...]) =>   begin
                            list = map(x -> x[1],
                                map(x -> interp(x, env, res_box), y))
                            #println("QUOTE", list)
                            return (list, env, res_box)
                        end
        
        c.ELE([v...]) =>   begin
                            ele = reduce( (x, y) -> x*""*y,
                                map(i -> interp(i, env, res_box, false)[1], v))
                            return (ele, env, res_box)
            
                        end
        c.CHAR(ch) => begin
                        atomic_ch = ch[1]
                        
                        if put_char == true

                            font_idx = 1
                            font_family = string(env["font"][font_idx])
                            font_family_length = length(font_family)
                            while !is_in_font(atomic_ch, font_family)
                                if font_idx <= font_family_length
                                    font_idx += 1
                                    font_family = string(env["font"][font_idx])
                                else
                                    font_list = string(env["font"])
                                    throw("the chars $atomic_ch is not contained in all the fonts
                                        listed in listed fonts: $font_list")
                                end
                            end


                            font_path = get_font_path(font_family)
                            font_size = parse(Int, env["fontsize"])
                            glyph_metrics = PDFOperating.check_char_size(
                                                atomic_ch, font_path, font_size)


                            push!(res_box.eles[end].eles,
                                u.ChBox(ch,
                                    font_path,
                                    font_size,
                                    glyph_metrics.ht,
                                    glyph_metrics.dp,
                                    glyph_metrics.wd))
                        end
                            return (ch, env, res_box)
                    end
        c.NL(nl) => return (nl, env, res_box)
        c.SPACE(sp) => return (sp, env, res_box)

        _ => begin
              println("不知道")
              val_evaled = "不知道"
              return (val_evaled, env, res_box)
            end
    end
end

function get_font_path(font_family)
    ptn = Fontconfig.Pattern(family=font_family)
    matched = Fontconfig.match(ptn)
    path = match(r"file=([^:]+)", string(matched))[1]
    return path
end

"""
check if the glyph of a char is contained by `font_family`
"""
function is_in_font(char, font_family)
    ptn = Fontconfig.Pattern(family=font_family)
    matched = Fontconfig.match(ptn)
    charset = match(r"charset=([^:]+)", string(matched))[1]
    splitted1 = split(charset, " ")
    splitted2 = map(x -> split(x, "-"), splitted1)

    """aux function"""
    regex_aux(x) = map(y -> padding_zero(y), x)

    x1 = map(x -> regex_aux(x), splitted2)
    x2 = map(x -> length(x) == 1 ? "\\u" * x[1] : "\\u" * x[1] * "-\\u" * x[2] , x1)
    regex_final = "[" * reduce((x,y)-> x*""*y, x2) * "]"
    regex_final_wrapped = Regex(regex_final)

    if match(regex_final_wrapped, string(char)) !== nothing
        return true
    else
        return false

    end
end

"""
padding zero for a hex-digit string `i` to make it a 4-digit.
- "27" -> "0027"
- "8af" -> "08af"
"""
function padding_zero(i)
    if length(i) == 2
        i="00"*i
    end
    if length(i)==3
        i="0"*i
    end
    return i
end



end