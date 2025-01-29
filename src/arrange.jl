module Arrange
using Match

u = Main.uahgi

# the cost of make ith to jth char a line
function cost(items, i, j, linewidth)
    slice = items[i:j]
    cost_list = map(x -> item_cost(x), slice)
    sum_of_cost_list = reduce((x, y)-> x+y, cost_list)
    if sum_of_cost_list > linewidth
        return Inf
    else
        return linewidth - sum_of_cost_list
    end
end

function item_cost(i)
    if typeof(i) == u.HGlue
        return i.wd
    elseif typeof(i) == u.ChBox
        return i.wd
    else
        return 0
    end
end

function arrange(vbox, env)
    result_vbox_inner = []
    linewidth = parse(Int, env["linewidth"])
    print(cost(vbox.eles[1].eles, 1, 20, linewidth))

    return vbox

end

end