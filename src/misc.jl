function Base.show(io::IO, ::MIME"text/plain", node::TreeNode)
    if !get(io, :compact, false)
        node.isroot ? println(io, "Node $(node.label) (root)") : println(io, "Node $(node.label): ")
        node.isroot ? println(io, "Ancestor : `nothing` (root)") : println(io, "Ancestor: $(node.anc.label), branch length = $(node.tau)")
        print(io, "$(length(node.child)) children: $([x.label for x in node.child])")
    end
    return nothing
end
function Base.show(io::IO, node::TreeNode)
	print(io, "$(typeof(node)): $(node.label)")
	node.isroot && print(io, " (root)")
	return nothing
end

function Base.show(io::IO, t::Tree{T}) where T
	nn = length(nodes(t))
	nl = length(leaves(t))
	long = begin
		base = "Tree{$T}: "
		base *= nn > 1 ? "$nn nodes, " : "$nn node, "
		base *= nl > 1 ? "$nl leaves" : "$nl leaf"
		base
	end
	if length(long) < 0.8*displaysize(io)[2]
		print(io, long)
		return nothing
	end

	short = begin
		base = "Tree w. "
		base *= nl > 1 ? "$nl leaves" : "$nl leaf"
		base
	end
	print(io, short)
	return nothing
end
function Base.show(io::IO, ::MIME"text/plain", t::Tree; maxnodes=40)
    if length(nodes(t)) < maxnodes
        print_tree_ascii(io, t)
    else
    	show(io, t)
    end
end

function print_tree_(io, node, cdepth; vindent=2, hindent=5, hoffset=0, maxdepth=5)
    hspace = ""
    for i in 1:hindent
        hspace *= "-"
    end
    offset = ""
    for i in 1:hoffset
        offset *= " "
    end
    if cdepth < maxdepth
    	println(io, "$offset $hspace $(node.label):$(node.tau)")
    elseif cdepth == maxdepth
    	if node.isleaf
    		println(io, "$offset $hspace $(node.label):$(node.tau)")
    	else
    		println(io, "$offset $hspace $(node.label):$(node.tau) ...")
    	end
    end
        #
    if cdepth <= maxdepth
        if !node.isleaf
            for c in node.child
                for i in 1:vindent
                    cdepth < maxdepth && println(io, "$offset $(" "^hindent)|")
                end
                print_tree_(io, c, cdepth + 1, vindent=vindent, hindent=hindent, hoffset=hoffset+hindent, maxdepth=maxdepth)
            end
        end
        #
    end
end
function print_tree(io, node::TreeNode; vindent=2, hindent=5, maxdepth=5)
    print_tree_(io, node, 1, vindent=vindent, hindent=hindent, hoffset=0, maxdepth=maxdepth)
end

print_tree(io, t::Tree; vindent=2, hindent=5, maxdepth=5) = print_tree(io, t.root; vindent=2, hindent=5, maxdepth=maxdepth)


"""
    print_tree_ascii(io, t::Tree)

Julia implementation of Bio.Phylo.draw_ascii function: 
https://github.com/biopython/biopython/blob/master/Bio/Phylo/_utils.py
"""
function print_tree_ascii(io, t::Tree)
    column_width = 80
    taxa = [ node.label for node in POTleaves(t)] #need leaves in Post-Order Traversal
    max_label_width = maximum([length(taxon) for taxon in taxa])
    drawing_width = column_width - max_label_width - 1
    drawing_height = 2 * length(taxa) - 1

    function get_col_positions(t::Tree)
        depths = [divtime(node, t.root) for node in values(t.lnodes)]
        # If there are no branch lengths, assume unit branch lengths
        if ismissing(maximum(depths))
            println(io, "\n not all branch lengths known, assuming identical branch lengths")
            depths = [node_depth(node) for node in values(t.lnodes)]
        end
        # Potential drawing overflow due to rounding -- 1 char per tree layer
        fudge_margin = ceil(Int64, log2(length(taxa)))
        if maximum(depths)==0
            cols_per_branch_unit = (drawing_width - fudge_margin)
        else
            cols_per_branch_unit = (drawing_width - fudge_margin) / maximum(depths)
        end
        return Dict(zip(keys(t.lnodes), round.(Int64,depths*cols_per_branch_unit .+2.0)))
    end

    function get_row_positions(t::Tree)
        positions = Dict{Any, Int64}(zip(taxa, 2 *(1:length(taxa)) ) )
        function calc_row(clade::TreeNode)
            for subclade in clade.child
                if !haskey(positions, subclade.label)
                    calc_row(subclade)
                end
            end
            if !haskey(positions, clade.label)
                positions[clade.label] = floor(Int64, (positions[clade.child[1].label] + positions[clade.child[end].label])/2)
            end
        end
        calc_row(t.root)
        return positions
    end

    col_positions = get_col_positions(t)
    row_positions = get_row_positions(t)
    char_matrix = [[" " for x in 1:(drawing_width+1)] for y in 1:(drawing_height+1)]

    function draw_clade(clade::TreeNode, startcol::Int64)
        thiscol = col_positions[clade.label]
        thisrow = row_positions[clade.label]
        # Draw a horizontal line
        for col in startcol:thiscol
            char_matrix[thisrow][col] = "_"
        end
        if !isempty(clade.child)
            # Draw a vertical line
            toprow = row_positions[clade.child[1].label]
            botrow = row_positions[clade.child[end].label]
            for row in (toprow+1):botrow
                char_matrix[row][thiscol] = "|"
            end
            # Short terminal branches need something to stop rstrip()
            if (col_positions[clade.child[1].label] - thiscol) < 2
                char_matrix[toprow][thiscol] = ","
            end
            # Draw descendents
            for child in clade.child
                draw_clade(child, thiscol + 1)
            end
        end
    end
    draw_clade(t.root, 1)
    # Print the complete drawing
    for i in 1:length(char_matrix)
        line = rstrip(join(char_matrix[i]))
        # Add labels for terminal taxa in the right margin
        if i % 2 == 0
            line = line * " " * strip(taxa[round(Int64, i/2)]) #remove white space from labels to make more tidy
        end
        println(io, line)
    end
end

"""
    check_tree(t::Tree; strict=true)
- Every non-leaf node should have at least one child (two if `strict`)
- Every non-root node should have exactly one ancestor
- If n.child[...] == c, c.anc == n is true
- Tree has only one root
"""
function check_tree(tree::Tree; strict=true)
    labellist = Dict{String, Int64}()
    nroot = 0
    flag = true
    for n in nodes(tree)
        if !n.isleaf && length(n.child)==0
        	(flag = false) || (@warn "Node $(n.label) is non-leaf and has no child.")
        elseif !n.isroot && n.anc == nothing
        	(flag = false) || (@warn "Node $(n.label) is non-root and has no ancestor.")
        elseif strict && length(n.child) == 1
            if !(n.isroot && n.child[1].isleaf)
        	   (flag = false) || (@warn "Node $(n.label) has only one child.")
            end
        elseif length(n.child) == 0 && !haskey(tree.lleaves, n.label)
            (flag = false) || (@warn "Node $(n.label) has no child but is not in `tree.lleaves`")
        end
        for c in n.child
            if c.anc != n
                (flag = false) || (@warn "One child of $(n.label) does not satisfy `c.anc == n`.")
            end
        end
        if get(labellist, n.label, 0) == 0
            labellist[n.label] = 1
        else
            labellist[n.label] += 1
            (flag = false) || (@warn "Label $(n.label) already exists!")
        end
        if n.isroot
            nroot += 1
        end
    end
    if nroot > 1
        (flag = false) || (@warn "Tree has multiple roots")
    elseif nroot ==0
        (flag = false) || (@warn "Tree has no root")
    end
    return flag
end

default_tree_label(n=10) = randstring(n)

make_random_label(base="NODE"; delim = "_") = make_random_label(base, 8; delim)
make_random_label(base, i; delim = "_") = base * delim * randstring(i)

function get_unique_label(t::Tree, base = "NODE"; delim = "_")
	label = make_random_label(base; delim)
	while haskey(t.lnodes, label)
		label = make_random_label(base; delim)
	end
	return label
end

function set_unique_label!(node::TreeNode, t::Tree; delim = "_")
	base = label(node)
	new_label = get_unique_label(t, base; delim)
	node.label = new_label
end

"""
    create_label(t::Tree, base="NODE")

Create new node label in tree `t` with format `\$(base)_i` with `i::Int`.
"""
function create_label(t::Tree, base="NODE")
    label_init = 1
    pattern = Regex(base)
    for n in values(t.lnodes)
        if match(pattern, n.label)!=nothing && parse(Int64, n.label[length(base)+2:end]) >= label_init
            label_init = parse(Int64, n.label[length(base)+2:end]) + 1
        end
    end
    return "$(base)_$(label_init)"
end




"""
    map_dict_to_tree!(t::Tree{MiscData}, dat::Dict; symbol=false, key = nothing)

Map data in `dat` to nodes of `t`. All node labels of `t` should be keys of `dat`. Entries of `dat` should be dictionaries, or iterable similarly, and are added to `n.data.dat`.
If `!isnothing(key)`, only a specific key of `dat` is added. It's checked for by `k == key || Symbol(k) == key` for all keys `k` of `dat`.
If `symbol`, data is added to nodes of `t` with symbols as keys.
"""
function map_dict_to_tree!(t::Tree{MiscData}, dat::Dict; symbol=false, key = nothing)
    for (name, n) in t.lnodes
        for (k,v) in dat[name]
            if !isnothing(key) && (k == key || Symbol(k) == key)
                n.data.dat[key] = v
            elseif isnothing(key)
                n.data.dat[symbol ? Symbol(k) : k] = v
            end
        end
    end
    nothing
end
"""
    map_dict_to_tree!(t::Tree{MiscData}, dat::Dict, key)
Map data in `dat` to nodes of `t`. All node labels of `t` should be keys of `dat`. Entries of `dat` corresponding to `k` are added to `t.lnodes[k].data.dat[key]`.
"""
function map_dict_to_tree!(t::Tree{MiscData}, dat::Dict, key)
    for (name, n) in t.lnodes
        n.data.dat[key] = dat[name]
    end
end

"""
    rand_times!(t[, p])

Add random branch lengths to tree distributed according to `p` (default [0,1]).
"""
function rand_times!(t, p)
    for n in values(t.lnodes)
        if !n.isroot
            n.tau = rand(p)
        end
    end

    return nothing
end
function rand_times!(t)
    for n in values(t.lnodes)
        if !n.isroot
            n.tau = rand()
        end
    end

    return nothing
end


