module Arrange
using Match

u = Main.uahgi

total_cost_table = Dict()

# the cost of make ith to jth item a line
function cost(items, i, j, linewidth, last_of_queue=false)
    slice = items[i:j]
    last = items[j]
    if typeof(last) == u.ChBox && last_of_queue === false
        return Inf
    end
    sum_of_cost_list = 0

    # add disc (after) if it exists
    
    if i > 2 && typeof(items[i-1]) == u.Disc
        previous = items[i-1]
        sum_of_cost_list += item_width(previous.after)
    end

    if typeof(last) != u.Disc
        cost_list = map(x -> item_width(x), slice)
        sum_of_cost_list += reduce((x, y)-> x+y, cost_list) - item_width(slice[end])
    else
        cost_list = map(x -> item_width(x), slice[1:end-1])
        if cost_list != []
            sum_of_cost_list += reduce((x, y)-> x+y, cost_list)
        end
        last_width = item_width(last.before)
        sum_of_cost_list += last_width
    end
    if sum_of_cost_list > linewidth
        return Inf
    else
        return (linewidth - sum_of_cost_list) ^ 3
    end
end

"""the total cost from 1 to n"""
function total_cost(items, n, linewidth, last_of_queue=false)
    if haskey(total_cost_table, n)
        return total_cost_table[n][1]
    end
    # first to nth item cost
    fst_to_nth_cost = cost(items, 1, n, linewidth, last_of_queue)

    if fst_to_nth_cost < Inf
        total_cost_table[n] = [fst_to_nth_cost, 0]
        return fst_to_nth_cost
    else
        mininal_cost = +Inf
        prev_breakpoint = nothing
        for j in 1:1:(n-1)
            total_c = total_cost(items, j, linewidth, false) 
            cost_tail = cost(items, j+1, n, linewidth, last_of_queue)
            if cost_tail < +Inf && last_of_queue == true
                tmp_cost = total_c
            else
                tmp_cost = total_c + cost_tail
            end
            if tmp_cost < mininal_cost
                mininal_cost = tmp_cost
                prev_breakpoint = j
            end
        end

        total_cost_table[n] = [mininal_cost, prev_breakpoint]
        return mininal_cost
    end
end

"""width of a item"""
function item_width(i)
    if typeof(i) == u.HGlue
        return i.wd
    elseif typeof(i) == u.ChBox
        return i.wd
    elseif typeof(i) == u.Disc
        return item_width(i.orig)
    else
        return 0
    end
end

function arrange(vbox, env)

    result_vbox_inner = [u.HBox([],nothing,nothing,nothing,nothing,nothing)]
    linewidth = parse(Int, env["linewidth"])
    eles = vbox.eles[1].eles
    total_cost(eles, length(eles), linewidth, true)


    current_point = length(eles)
    breakpoint_list = [current_point]
    while total_cost_table[current_point][2] !== 0.0
        current_point = total_cost_table[current_point][2]
        push!(breakpoint_list, current_point)
    end

    breakpoint_list_reversed = reverse(breakpoint_list)
    for (x, i) in enumerate(1:1:length(eles))
        item = eles[x]
        if !(x in breakpoint_list_reversed)
            if typeof(item) == u.Par
                horizonal_align = env["hori_align"]
                result_vbox_inner[end].eles = add_aligner(result_vbox_inner[end].eles, horizonal_align)
                push!(result_vbox_inner, u.HBox([],nothing,nothing,nothing,nothing,nothing))
            elseif typeof(item) == u.Disc
                if item.orig != []
                    push!(result_vbox_inner[end].eles, item.orig)
                end
            else
                push!(result_vbox_inner[end].eles, item)
            end
        # x is the last one
        elseif i ==  length(eles)
            if typeof(item) !== u.Par
                push!(result_vbox_inner[end].eles, item)
            end
        # x in breakpoint_list_reversed
        else
            if typeof(item) == u.Par
                push!(result_vbox_inner, u.HBox([],nothing,nothing,nothing,nothing,nothing))

            elseif typeof(item) == u.Disc
                if item.before != []
                    push!(result_vbox_inner[end].eles, item.before)
                end
                push!(result_vbox_inner, u.HBox([],nothing,nothing,nothing,nothing,nothing))
                if item.after != []
                    push!(result_vbox_inner[end].eles, item.after)
                end
            else
                push!(result_vbox_inner, u.HBox([],nothing,nothing,nothing,nothing,nothing))
            end
        end
    end

    return result_vbox_inner
end

function add_aligner(hbox_eles, horizonal_align)
    aligner_glue = u.HGlue(0.0,10000.0)
    if horizonal_align == "right"
        hbox_eles = reverse(push!(reverse(hbox_eles), aligner_glue))
    elseif horizonal_align == "middle"
        return hbox_eles
    else # left/default
        hbox_eles = push!(hbox_eles, aligner_glue)
    end
    return hbox_eles
end

function position(box_inner, env#=to be used later=#)
    pages = [] #a subarray is the content of a page
    orig_y = 700 # it can be derived from env
    orig_x = 100 # it can be derived from env
    posX = orig_x #cursor x
    posY = orig_y #cursor y
    baselineskip = 30  # it can be derived from env
    linewidth = env["linewidth"]
    horizonal_align = env["hori_align"]

    for (idx, hbox) in enumerate(box_inner)
        hbox_eles = hbox.eles
        aligner_glue = u.HGlue(0.0,10000.0)
        if idx == length(box_inner)
            hbox_eles = add_aligner(hbox_eles, horizonal_align)
        end
        residual_space = parse(Float64, linewidth) - width_sum_of_eles(hbox.eles)
        sum_of_stretch = reduce((x,y) -> x+y, map(hglue_stretch, hbox.eles))
        space_stretch_ratio =  residual_space / sum_of_stretch

        pages = position_chbox(hbox_eles, pages, posX, posY, space_stretch_ratio)
        posX = orig_x
        posY -= baselineskip
    end
    return pages
end

function hglue_stretch(ele)
    if typeof(ele) == u.HGlue
        return ele.stretch # stretch
    else
        return 0
    end

end

function width_sum_of_eles(eles)
    width_sum = x -> begin
        if hasproperty(x, :wd)
            return x.wd
        else
            return 0.0
        end
    end
    if length(eles) == 0
        return 0
    elseif length(eles) == 1
        return width_sum(eles[1])
    else
        return reduce((x,y)-> x+y, map(width_sum, eles))
    end
end

"""positioning all the chboxes in a HBox"""
function position_chbox(hbox_eles, pages, posX, posY, space_stretch_ratio)
    for i in hbox_eles
        if typeof(i) == u.HGlue
            deltaX = i.wd + (i.stretch * space_stretch_ratio)
            posX += deltaX
        else #ChBox
            deltaX = i.wd 
            i.x = posX
            i.y = posY
            push!(pages, i)
            posX += deltaX
        end
    end
    return pages
end
end
