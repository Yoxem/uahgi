module Interp
using Match
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
- res_box: the generated result box containing the content
"""
function interp(ast, env, res_box, put_char=true)
    #println("INTERP", ast)
    @match ast begin
        c.SEQ([c.ELE([c.ID("def")]),
            c.ELE([c.ID(id)]),val]) => 
                        begin
                            (val_evaled, env, res_box) = interp(val, env, res_box)
                            println("ID~~~", id, " VAL~~~", val_evaled)
                            env[id] = val_evaled
                            return (val_evaled, env, res_box)
                        end
        c.SEQ([c.ELE([c.ID("quote")]),
            y...]) =>   begin
                            list = map(x -> x[1],
                                map(x -> interp(x, env, res_box), y))
                            println("QUOTE", list)
                            return (list, env, res_box)
                        end
        
        c.ELE([v...]) =>   begin
                            ele = reduce( (x, y) -> x*""*y,
                                map(i -> interp(i, env, res_box, false)[1], v))
                            return (ele, env, res_box)
            
                        end
        c.CHAR(ch) => begin
                        ret = ch
                        if put_char == true
                            push!(res_box.eles[end].eles,
                                #=TODO: check single-char size
                                env[""]
                                =#
                                u.ChBox(ch, "foo", 20, 1, 2, 3))
                        end
                        return (ret, env, res_box)
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

end