export print_tree, hamming, check_tree, nodeinfo

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
    nodeinfo(node::TreeNode)

Print information about `node`. 
"""
function nodeinfo(node)
    println("Node $(node.label): ") 
    println("Ancestor: $(node.anc.label), tau = $(node.data.tau)")
    println("$(length(node.child)) children: $([x.label for x in node.child])")
    println("Brothers: $([x.label for x in node.anc.child])")
end


"""
    print_tree(node::TreeNode; vindent=2, hindent=5, hoffset=0)
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

# """
# """
# function print_tree(node::TreeNode; indent = 0, indent_size = 10)

#     ## Printing top child
#     node.isleaf || print_tree(node.child[1], indent = indent+1, indent_size = indent_size)

#     ## Current node
#     # Top vertical connection for non leaf
#     if !node.isleaf
#             for i in 1:(indent_size*(indent))
#                     print(" ")
#             end
#             println("|")
#     end     
#     # Indent and horizontal connection
#     for i in 1:(indent_size*indent)
#             (i<=(indent_size*(indent-1))+1) ? print(" ") : print("-")
#     end
#     # Current node label
#     print(node.label)
#     ismissing(node.data.tau) ? println() : println(":$(node.data.tau)")
#     # Bottom vertical connection for non leaf
#     if !node.isleaf
#             for i in 1:(indent_size*(indent))
#                     print(" ")
#             end
#             println("|")
#     end     

#     ## Printing bottom child
#     node.isleaf || print_tree(node.child[2], indent = indent+1,  indent_size = indent_size)

#     return nothing
# end

# """
# """
# function print_tree(tree::Tree; indent = 0, indent_size = 10)
#     print_tree(tree.root, indent=indent, indent_size=indent_size)
# end

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

- Every non-leaf node should have at least one child
- Every non-root node should have exactly one ancestor
- If n.child[...] == c, c.anc == n is true
- Tree has only one root
"""
function check_tree(tree)
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