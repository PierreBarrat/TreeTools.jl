function showinfo(tree::Tree)
    i = 1
    for n in values(tree.lnodes)
        println("Node $i: $(n.label)")
        n.isroot ? println("Root") : println("Ancestor: $(n.anc.label)")
        if n.isleaf
            println("Leaf")
        else
            print("Children: ")
            for c in n.child
                print(" $(c.label), ")
            end
            println()
        end
        i+=1
        println()
    end
end

"""
    show(io::IO, tree::Tree, maxnodes=40; kwargs...)
    show(t::Tree, maxnodes=40; kwargs...)
"""
function Base.show(io::IO, tree::Tree, maxnodes=40; kwargs...)
    if length(tree.lnodes) < maxnodes
        print_tree(io, tree; kwargs...)
    end
end
Base.show(t::Tree, maxnodes=40; kwargs...) = show(stdout, t, maxnodes; kwargs...)

function Base.show(io::IO, n::TreeNode)
    if !get(io, :compact, false)
        nodeinfo(io, n)
    end
end
Base.show(n::TreeNode) = show(stdout, n)

"""
    nodeinfo(io, node)

Print information about `node`.
"""
function nodeinfo(io, node)
    println(io, "Node $(node.label): ")
    node.isroot ? println(io, "Ancestor : none (root)") : println(io, "Ancestor: $(node.anc.label), tau = $(node.tau)")
    println(io, "$(length(node.child)) children: $([x.label for x in node.child])")
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
    for n in values(tree.lnodes)
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

function set_unique_label!(node::TreeNode, t::Tree; delim = '|')
	id = randstring(5)
	node.label *= delim * id
	while haskey(t.lnodes, node.label)
		node.label = node.label[1:end-5] * randstring(5)
	end
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
    rand_times!(t, p)

Add random branch lengths to tree.
"""
function rand_times!(t, p)
    for n in values(t.lnodes)
        if !n.isroot
            n.tau = rand(p)
        end
    end
end


##################################################
##### Utilities for dicts with nested keys #######
##################################################
function recursive_key_init!(dat, key, ks...)
    if !haskey(dat, key)
        dat[key] = Dict()
    end
    recursive_key_init!(dat[key], ks...)
end
recursive_key_init!(dat) = nothing
function recursive_get(dat, key, ks...)
    if isempty(ks)
        return dat[key]
    else
        return recursive_get(dat[key], ks...)
    end
end
recursive_get(dat, key::Tuple) = recursive_get(dat, key...)
function recursive_set!(dat, value, key, ks...)
    if isempty(ks)
        dat[key] = value
    else
        if !haskey(dat, key)
            dat[key] = Dict()
        end
        recursive_set!(dat[key], value, ks...)
    end
    dat
end
recursive_set!(dat, value, key::Tuple) = recursive_set!(dat, value, key...)
function recursive_push!(dat, value, key, ks...)
    if isempty(ks)
        push!(dat[key], value)
    else
        recursive_push!(dat[key], value, ks...)
    end
    dat
end
recursive_push!(dat, value, key::Tuple) = recursive_push!(dat, value, key...)
function recursive_haskey(dat, key, ks...)
    if !haskey(dat, key)
        return false
    elseif isempty(ks)
        return true
    else
        return recursive_haskey(dat[key], ks...)
    end
end
