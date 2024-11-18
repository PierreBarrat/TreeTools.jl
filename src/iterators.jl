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
function nodes(t::Tree; skiproot=false)
    return if skiproot
        Iterators.filter(x -> !isroot(x), values(t.lnodes))
    else
        values(t.lnodes)
    end
end
leaves(t::Tree) = values(t.lleaves)
function internals(t::Tree; skiproot=false)
    return if skiproot
        Iterators.filter(x -> !isleaf(x) && !isroot(x), values(t.lnodes))
    else
        Iterators.filter(x -> !isleaf(x), values(t.lnodes))
    end
end

nodes(f::Function, t::Tree) = filter(f, values(t.lnodes))

#=============================================================================#
########################## Post-order (leaves first) ##########################
#=============================================================================#

# Helper function useful for pre and post order
function _subtrees_visited(next, head)
    for c in children(next)
        if c === head
            return true
        end
    end
    return false
end

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
    f::Function, node::TreeNode; root=true, leaves=true, internals=true
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
    return _postorder(_f, node)
end
function postorder_traversal(f, tree::Tree; kwargs...)
    return postorder_traversal(f, root(tree); kwargs...)
end
postorder_traversal(tree; kwargs...) = postorder_traversal(x -> true, tree; kwargs...)

# For backward compat
POT(node) = postorder_traversal(x -> true, node)
POT(tree::Tree) = POT(root(tree))
POTleaves(node) = postorder_traversal(x -> true, node; internals=false)
POTleaves(tree::Tree) = POTleaves(root(tree))

@resumable function _postorder(node::TreeNode{T}) where {T}
    stack = TreeNode{T}[node]
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
@resumable function _postorder(filter_func, node::TreeNode{T}) where {T}
    stack = TreeNode{T}[node]
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

#===================================================================================#
############################ Pre-order (ancestors first) ############################
#===================================================================================#
function preorder_traversal(
    f::Function, node::TreeNode; root=true, leaves=true, internals=true
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
    return _preorder(_f, node)
end
preorder_traversal(f, tree::Tree; kwargs...) = preorder_traversal(f, root(tree); kwargs...)
preorder_traversal(tree; kwargs...) = preorder_traversal(x -> true, tree; kwargs...)

@resumable function _preorder(filter_func, node::TreeNode{T}) where {T}
    stack = TreeNode{T}[node]
    while !isempty(stack)
        next = pop!(stack)
        for c in Iterators.reverse(children(next))
            push!(stack, c)
        end
        if filter_func(next)
            @yield next
        end
    end
    return nothing
end
@resumable function _preorder(node::TreeNode{T}) where {T}
    stack = TreeNode{T}[node]
    while !isempty(stack)
        next = pop!(stack)
        for c in Iterators.reverse(children(next))
            push!(stack, c)
        end
        @yield next
    end
    return nothing
end

#=============================================#
################ Traversal hub ################
#=============================================#

const traversal_styles = Dict(
    :postorder => postorder_traversal, :preorder => preorder_traversal
)
"""
    traversal([f], tree, style=:postorder; internals, leaves, root)
    traversal([f], node, style=:postorder; internals, leaves, root)

Iterate through nodes of `tree` according to `style`, skipping nodes for which
`f` returns `false`.
`style` must be in `collect(keys(TreeTools.traversal_styles))`.
For now its just `:postorder`.

See `postorder_traversal` for extended docstring.
"""
function traversal(f, tree, style::Symbol=:postorder; kwargs...)
    if haskey(traversal_styles, style)
        return traversal_styles[style](f, tree; kwargs...)
    else
        throw(ArgumentError("""
        traversal style must be in $(collect(keys(traversal_styles))). Instead $style.
        """))
    end
end
function traversal(tree, style::Symbol=:postorder; kwargs...)
    return traversal(x -> true, tree, style; kwargs...)
end
