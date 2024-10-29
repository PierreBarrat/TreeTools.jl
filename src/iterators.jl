#===================================================#
################## Arbitrary order ##################
#===================================================#

"""
	nodes(t; skiproot=false)
	leaves(t)
	internals(t; skiproot=false)

Iterator over all nodes / leaves / internal nodes of a tree.
If `skiproot`, the root node will be skipped by the iterator.

# Note
`length` cannot be called on `internals(t)` as the latter is based on `Iterators.filter`.
  A way to get the number of internal nodes of a tree is for example by calling
  `length(nodes(t)) - length(leaves(t))`.
"""
nodes, leaves, internals
function nodes(t::Tree; skiproot = false)
	return if skiproot
		Iterators.filter(x -> !isroot(x), values(t.lnodes))
	else
		values(t.lnodes)
	end
end
leaves(t::Tree) = values(t.lleaves)
function internals(t::Tree; skiproot = false)
	return if skiproot
		Iterators.filter(x->!x.isleaf && !isroot(x), values(t.lnodes))
	else
		Iterators.filter(x->!x.isleaf, values(t.lnodes))
	end
end

nodes(f::Function, t::Tree) = filter(f, values(t.lnodes))


#=============================================================================#
########################## Post-order (leaves first) ##########################
#=============================================================================#

"""
    postorder_traversal([f], tree; root=true, leaves=true, internals=true)

Traverse `tree` in postorder, iterating over nodes.
The children of `node` are returned in the same order as `children(node)`.

Keep only nodes `n` such that `f(n)` is true.
If `leaves`, `internals` or `root` are set to `false`, the corresponding nodes are excluded.

## Examples
```julia
for node in postorder_traversal(tree; root=false)
    isroot(node) # always false
end

[label(x) for x in postorder_traversal(tree; internals=false)] # labels of leaf nodes
```
"""
function postorder_traversal(
    f::Function, node::TreeNode; root=true, leaves=true, internals=true,
)
    function _f(n)
        if !root && isroot(n)
            return false
        end
        if !internals && isinternal(n)
            return false
        end
        if !leaves && isleaf(n)
            return false
        end
        if !f(n)
            return false
        end
        return true
    end
    return _POT(_f, node)
end
postorder_traversal(f, tree::Tree; kwargs...) = postorder_traversal(f, root(tree); kwargs...)
postorder_traversal(tree; kwargs...) = postorder_traversal(x -> true, tree; kwargs...)

@resumable function _POT(node::TreeNode{T}) where T
    stack = TreeNode{T}[node]
    isempty(stack) && return nothing
    head = stack[end]
    while !isempty(stack)
        next = stack[end]
        # Main.@infiltrate
        if next.isleaf || _subtrees_visited(next, head)
            head = next
            pop!(stack)
            @yield next
        else
            for c in Iterators.reverse(children(next))
                push!(stack, c)
            end
        end
    end
    return nothing
end
@resumable function _POT(filter_func, node::TreeNode{T}) where T
    stack = TreeNode{T}[node]
    isempty(stack) && return nothing
    head = stack[end]
    while !isempty(stack)
        next = stack[end]
        # Main.@infiltrate
        if next.isleaf || _subtrees_visited(next, head)
            head = next
            pop!(stack)
            if filter_func(next)
                @yield next
            end
        else
            for c in Iterators.reverse(children(next))
                push!(stack, c)
            end
        end
    end
    return nothing
end

function _subtrees_visited(next, head)
    for c in children(next)
        if c === head
            return true
        end
    end
    return false
end

#=============================================#
################ Traversal hub ################
#=============================================#


const traversal_styles = Dict(:postorder => postorder_traversal)
function traversal(f, tree::Tree, style::Symbol; kwargs...)
    if haskey(traversal_styles, style)
        return traversal_styles[style](f, tree; kwargs...)
    else
        throw(ArgumentError("""
        traversal style must be in $(collect(keys(traversal_styles))). Instead $style.
        """))
    end
end
function traversal(tree::Tree, style::Symbol; kwargs...)
    return traversal(x -> true, tree, style; kwargs...)
end
