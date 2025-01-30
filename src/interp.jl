module Interp
using Match
using Fontconfig

include("pdfoperating.jl")
using .PDFOperating

u = Main.uahgi
c = Main.uahgi.Parsing.Passes.Classes

@enum PutChar begin
    true_ = 0
    false_ = 1
    gen_chbox_ = 2
end

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
- put_char(PutChar): if the character should be put into the res_box. 
"""
function interp(ast, env, res_box, put_char=true_)
    #println("INTERP", ast)
    @match ast begin
        c.ID(id) => 
            begin
                print("ID____", id)
                return interp(env[id], env, res_box, true_)
            end
        c.SEQ([c.ELE([c.ID("def")]),
            c.ELE([c.ID(id)]),val]) => 
                        begin
                            (val_evaled, env, res_box) = interp(val, env, res_box, false_)
                            #println("ID~~~", id, " VAL~~~", val_evaled)
                            if !haskey(env, id)
                                env[id] = val_evaled
                            else
                                throw("the variable $id has been defined.")
                            end
                            return (val_evaled, env, res_box)
                        end
        c.SEQ([c.ELE([c.ID("set")]),
            c.ELE([c.ID(id)]),val]) => 
                    begin
                        (val_evaled, env, res_box) = interp(val, env, res_box, false_)
                        #println("ID~~~", id, " VAL~~~", val_evaled)
                        if haskey(env, id)
                            env[id] = val_evaled
                        else
                            throw("the variable $id is not defined yet.")
                        end
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
                                map(i -> interp(i, env, res_box, false_)[1], v))
                            return (ele, env, res_box)
            
                        end
        c.SEQ([c.ELE([c.ID("par")])]) =>begin
                                            push!(res_box.eles, u.HBox([],
                                             nothing, nothing, nothing, nothing, nothing))
                                            return (ast, env, res_box)
                                        end
        c.SEQ([c.ELE([c.ID("ex")]), val]) =>begin
                                        x = 'x'
                                        font_family = select_font(x, env)
                                        font_path = get_font_path(font_family)
                                        font_size = parse(Int, env["fontsize"])
                                        charmetrics = PDFOperating.check_char_size(
                                            'x',
                                            font_path,
                                            font_size)
                                        ex_in_px = charmetrics.wd
                                        (val, _, _) = interp(val, env, res_box, false_)
                                        val_ex_in_px = ex_in_px * parse(Float64,val)
                                        return (val_ex_in_px, env, res_box)
                                    end
        c.SEQ([c.ELE([c.ID("hglue")]),
            width,stretch]) => begin
                                    if put_char == true_
                                        (width_evaled, _, _) = interp(width, env, res_box, false_)
                                        (stretch_evaled, _, _) = interp(stretch, env, res_box, false_)
                                        push!(res_box.eles[end].eles,
                                            u.HGlue(width_evaled, parse(Float64, stretch_evaled))
                                        )
                                    end

                                    return (ast, env, res_box)
                                end

        c.CHAR(ch) => begin
                        atomic_ch = ch[1]

                        if put_char == false_
                            return (ch, env, res_box)
                        end

                        font_family = select_font(atomic_ch, env)

                        font_path = get_font_path(font_family)
                        font_size = parse(Int, env["fontsize"])
                        glyph_metrics = PDFOperating.check_char_size(
                                            atomic_ch, font_path, font_size)
                        chbox = u.ChBox(ch,
                            font_path,
                            font_size,
                            glyph_metrics.ht,
                            glyph_metrics.dp,
                            glyph_metrics.wd,
                            nothing, nothing)
                        
                        if put_char == true_
                            push!(res_box.eles[end].eles, chbox)
                            return (ch, env, res_box)
                        else # put_char == gen_chbox_
                            return (chbox, env, res_box)
                        
                        end
                    end

        c.SEQ([c.ELE([c.ID("disc")]),
                c.ELE(before),
                c.ELE(after),
                c.ELE(orig)])=> begin
                before_item = length(before) == 0 ? [] : before[1]
                after_item = length(after) == 0 ? [] : after[1]
                orig_item = length(orig) == 0 ? [] : orig[1]

                (before_evaled, _, _) = interp(before_item, env, res_box, gen_chbox_)
                (after_evaled, _, _) = interp(after_item, env, res_box, gen_chbox_)
                (orig_evaled, _, _) = interp(orig_item, env, res_box, gen_chbox_)
                ret = u.Disc(before_evaled, after_evaled, orig_evaled)
                push!(res_box.eles[end].eles, ret)
                return (ret, env, res_box)
            
            end
        c.NL(nl) => begin
                        #if spacing defined
                        if haskey(env, "spacing")
                            (spacing, _, _) = interp(env["spacing"], env, res_box, false_)
                            add_spacing = interp(spacing, env, res_box, true_)
                        end
                        return (nl, env, res_box)
                    end
        c.SPACE(sp) => begin
                            #if spacing defined
                            if haskey(env, "spacing")
                                (spacing, _, _) = interp(env["spacing"], env, res_box, false_)
                                add_spacing = interp(spacing, env, res_box, true_)
                            end
                            return (sp, env, res_box)
                        end
        # empty item
        [] => return (ast, env, res_box)
        _ => begin
              println("unknown token", ast)
              val_evaled = nothing
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

"""
Select proper font having the glyph of char `ch`
"""
function select_font(ch, env)
    font_idx = 1
    font_family = string(env["font"][font_idx])
    font_family_length = length(font_family)
    while !is_in_font(ch, font_family)
        if font_idx <= font_family_length
            font_idx += 1
            font_family = string(env["font"][font_idx])
        else
            font_list = string(env["font"])
            throw("the chars $atomic_ch is not contained in all the fonts
                listed in listed fonts: $font_list")
        end
    end
    return font_family
end

end