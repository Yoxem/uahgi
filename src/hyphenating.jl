"""
using Knuth-liang's pattern-matching hyphenating algorithm.
"""
module Hyphenating
using Match
c = Main.uahgi.Parsing.Passes.Classes

function match_lang(item)
    @match item begin
    c.SEQ([c.ELE([c.ID("lang")]), c.ELE([c.CHAR(v1)])]) => begin
        return v1
        end
    _ => false
    end
end

"""
check the language indicated by .ug file
"""
function check_lang(ast)
    ast_tree = ast.val
    result = map(x -> match_lang(x), ast_tree)
    lang = result[1]

    if lang != false
        return lang
    else
        return nothing
    end

    
end

function remove_num_from_pattern(ptn)
    ptn1 = replace(ptn, r"^\." => "^")
    ptn2 = replace(ptn1, r"\.$" => "\$")
    ptn3 = replace(ptn2, r"\d" => "")
    return ptn3

end

function hyphenate_aux(chars, patterns)
    level_of_chars = fill(0, length(chars))

    y = filter(x -> (match(Regex(x[1]), chars) !== nothing),patterns)
    z = map(x -> (x[1], x[2],
        map(x -> x.offset, collect(eachmatch(Regex(x[1]), chars)))), y)
    for ptn in z
        for offset in ptn[3]
            counter = 0
            for ptn_char in ptn[2]
                if match(r"[a-z]", string(ptn_char)) !== nothing
                    counter += 1
                elseif match(r"[.]", string(ptn_char)) !== nothing
                    counter = 0
                else
                    # 1-5
                    if offset + counter -1 != 0
                        orig = level_of_chars[offset + counter-1]
                        new = parse(Int, ptn_char)
                        if new > orig
                            level_of_chars[offset + counter-1] = new
                        end
                    end
                    counter += 0
                end
            end
        end
    end
    new_chars = ""
    for (idx, char) in enumerate(chars)
        new_chars *= char
        level_after_char = level_of_chars[idx]
        if (level_after_char > 0) && (level_after_char % 2 == 1)
            new_chars *= "~" # for hyphenation
        end
    end
    return new_chars

end

function match_char(ast_item, patterns)
    @match ast_item begin
        c.CHAR(chars), if match(r"[a-zA-Z]+", chars) !== Nothing end =>
            begin
                raw_result = hyphenate_aux(chars, patterns)
                splitted = split(raw_result, "~")
                final = []
                for i in splitted
                    push!(final, c.CHAR(i))
                    push!(final, c.SEQ([c.ELE([c.ID("disc")]),
                                        c.ELE([]),
                                        c.ELE([]),
                                        c.ELE([c.CHAR("-")])]))
                end

                final = final[1:end-1]
                return final
                #c.CHAR(hyphenate_aux(chars, patterns))
            end
        c.SEQ(v) => c.SEQ(map(x -> match_char(x, patterns), v))
        _ => ast_item
    end
end

function hyphenate(ast)
    lang = check_lang(ast)
    if lang !== nothing
        include("hyphenRules/$lang.jl")
        patterns = Hyphen.patterns
        pattern_with_orig = map(x->(remove_num_from_pattern(x), x),
                                patterns)
                                
        new_ast_val = map(x -> match_char(x, pattern_with_orig), ast.val)
        
        

        new_ast_val2 = []
        for i in new_ast_val
            @match i begin
                [x] => push!(new_ast_val2, x)
                [x,y] =>begin new_ast_val2 = vcat(new_ast_val2, i) end
                [x,y...,z] =>begin new_ast_val2 = vcat(new_ast_val2, i) end
                _ => push!(new_ast_val2, i)
            end
        end

        new_ast_val3 = []
        for i in new_ast_val2
            @match i begin
                c.CHAR(val=r"[a-zA-Z]+") => begin
                                                new_ast_val3 = vcat(new_ast_val3,
                                                map(q -> c.CHAR(q), split(i.val, "")))
                                            end
                _ => push!(new_ast_val3, i)
            end
        end
        return c.PROG(new_ast_val3)
    else
        return ast
    end
end

end