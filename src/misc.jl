import Base.show 
export print_tree, check_tree, nodeinfo, show

function showinfo(tree::Tree)
    i = 1
    for n in values(tree.nodes)
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
"""
function show(io::IO, tree::Tree)
    if length(tree.nodes) < 40
        print_tree(tree)
    end
end
show(t::Tree) = show(stdout, t)
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
function print_tree(node; vindent=2, hindent=5, hoffset=0)
    hspace = ""
    for i in 1:hindent
        hspace *= "-"
    end
    offset = ""
    for i in 1:hoffset
        offset *= " "
    end

    println("$offset $hspace $(node.label):$(node.data.tau)")
    
    if !node.isleaf
        for c in node.child
            for i in 1:vindent
                println("$offset $(" "^hindent)|")
            end
            print_tree(c, vindent=vindent, hindent=hindent, hoffset=hoffset+hindent)
        end
    end
end
print_tree(t::Tree; vindent=2, hindent=5, hoffset=0) = print_tree(t.root; vindent=2, hindent=5, hoffset=0)




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
    check_tree(t::Tree)

- Every non-leaf node should have at least one child
- Every non-root node should have exactly one ancestor
- If n.child[...] == c, c.anc == n is true
- Tree has only one root
"""
function check_tree(tree::Tree)
    labellist = Dict{String, Int64}()
    nroot = 0
    for n in values(tree.nodes)
        if !n.isleaf && length(n.child)==0
        	@warn "Node $(n.label) is non-leaf and has no child."
        elseif !n.isroot && n.anc == nothing
        	@warn "Node $(n.label) is non-root and has no ancestor."
        elseif !n.isroot && length(n.child) == 1
        	@warn "Node $(n.label) has only one child."
        end
        for c in n.child
            if c.anc != n
                @warn "One chilf of $(n.label) does not satisfy `c.anc == n`."
            end
        end
        if get(labellist, n.label, 0) == 0
            labellist[n.label] = 1
        else
            labellist[n.label] += 1
            @warn "Label $(n.label) already exists!"
        end
        if n.isroot
            nroot += 1
        end
    end
    if nroot > 1
        @warn "Tree has multiple roots"
    elseif nroot ==0
        @warn "Tree has no root"
    end
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