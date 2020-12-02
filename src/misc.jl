import Base.show 
export print_tree, check_tree, nodeinfo, show

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
function show(io::IO, tree::Tree, maxnodes=40; kwargs...)
    if length(tree.lnodes) < maxnodes
        print_tree(tree; kwargs...)
    end
end
show(t::Tree, maxnodes=40; kwargs...) = show(stdout, t, maxnodes; kwargs...)
function show(io::IO, n::TreeNode)
    # println("### TreeNode:")
    # println("Label $(n.label)")
    # println("Ancestor $n.anc.label")
    # println("Number of children $(length(n.child))")
    nodeinfo(n)
end
show(n::TreeNode) = show(stdout, n)

"""
    nodeinfo(node::TreeNode)

Print information about `node`. 
"""
function nodeinfo(node)
    println("Node $(node.label): ") 
    node.isroot ? println("Ancestor : none (root)") : println("Ancestor: $(node.anc.label), tau = $(node.data.tau)")
    println("$(length(node.child)) children: $([x.label for x in node.child])")
    # println("Brothers: $([x.label for x in node.anc.child])")
end


"""
    print_tree(node::TreeNode; vindent=2, hindent=5, hoffset=0)
    print_tree(t::Tree; vindent=2, hindent=5, hoffset=0)
"""
function print_tree_(node, cdepth; vindent=2, hindent=5, hoffset=0, maxdepth=4)
    hspace = ""
    for i in 1:hindent
        hspace *= "-"
    end
    offset = ""
    for i in 1:hoffset
        offset *= " "
    end
    cdepth <= maxdepth && println("$offset $hspace $(node.label):$(node.data.tau)")
        #
    if cdepth <= maxdepth
        if !node.isleaf
            for c in node.child
                for i in 1:vindent
                    cdepth < maxdepth && println("$offset $(" "^hindent)|")
                end
                print_tree_(c, cdepth + 1, vindent=vindent, hindent=hindent, hoffset=hoffset+hindent, maxdepth=maxdepth)
            end
        end
        #
    end
end
function print_tree(node::TreeNode; vindent=2, hindent=5, maxdepth=4)
    print_tree_(node, 1, vindent=vindent, hindent=hindent, hoffset=0, maxdepth=maxdepth)
end
print_tree(t::Tree; vindent=2, hindent=5, maxdepth=4) = print_tree(t.root; vindent=2, hindent=5, maxdepth=maxdepth)




"""
    hamming(x,y)
"""
function hamming(x,y)
    if typeof(x) != typeof(y)
            @warn "Computing hamming distance between different types."
    elseif length(x) != length(y)
            error("Computing hamming distance between objects of different lengths")
    end
    return sum(x .!= y)
end

"""
"""
function hamming(x::String, y::String; seqtype=:nucleotide)
    if typeof(x) != typeof(y)
            @warn "Computing hamming distance between different types."
    elseif length(x) != length(y)
            error("Computing hamming distance between objects of different lengths")
    end
    out = 0
    for (a,b) in zip(x,y)
        if seqtype==:nucleotide
            if in(a,"ACGT") && in(b,"ACGT")
                out += a!=b
            end    
        else
            out += a!=b
        end
    end
    return out
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
    for n in values(tree.lnodes)
        if !n.isleaf && length(n.child)==0
        	(flag = false) || (@warn "Node $(n.label) is non-leaf and has no child.")
        elseif !n.isroot && n.anc == nothing
        	(flag = false) || (@warn "Node $(n.label) is non-root and has no ancestor.")
        elseif !n.isroot && strict && length(n.child) == 1
        	(flag = false) || (@warn "Node $(n.label) has only one child.")
        elseif !n.isroot && length(n.child) == 0 && !haskey(tree.lleaves, n.label)
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
# check_tree(t::Tree) = check_tree(t.root)


"""
    get_node_dates!(t::Tree{LBIData}, dat)

Get dates of nodes of `t` using data `dat`. Iterating through `dat` should give elements of format `(name, date)` where `name` is a label of a node. 
"""
function get_node_dates!(t::Tree{LBIData}, dat)
    for (n,d) in dat
        if haskey(t.lnodes, n)
            t.lnodes[n].data.date = d
        end
    end
end