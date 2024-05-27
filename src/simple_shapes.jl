"""
    star_tree(n, times)

Create a star tree with `n` leaves.
`times` can be an iterable of length `n` or a number/missing.
"""
function star_tree(n::Integer, time::Union{Missing, Real} = missing)
    return star_tree(n, Iterators.map(x -> time, 1:n))
end
function star_tree(n::Integer, time_vals)
    @assert n > 0 "Number of leaves must be positive"
    @assert length(time_vals) == n "Number of leaves and times must match - \
        Instead $n and $(length(time_vals))"

    tree = Tree(TreeNode(; label="root"))
    for (i, t) in enumerate(time_vals)
        graft!(tree, TreeNode(; label="$i", tau=t), "root"; graft_on_leaf=true)
    end
    return tree
end

#=
The code proceeds by recursively grafting asymetric shapes (An:(T-τ),Bn:τ) onto B_(n-1)
=#
function ladder_tree(n::Integer, T::Union{Missing, Real} = missing)
    @assert n > 0 "Number of leaves must be positive"

    if n == 1
        return Tree(TreeNode(; tau = T))
    end

    τ = ismissing(T) ? missing : T / (n-1)
    tree = Tree(TreeNode(; label = "root"))
    # first two nodes of the ladder
    graft!(tree, TreeNode(; label = "$n", tau=T), "root"; graft_on_leaf=true)
    node = graft!(tree, TreeNode(; tau=τ), "root")
    _ladder_tree!(tree, label(node), n-1, T-τ, τ)
    return tree
end

function _ladder_tree!(tree, node, n, T, τ)
    # graft the next leaf on node
    if n > 1
        graft!(tree, TreeNode(; label = "$n", tau = T), node; graft_on_leaf=true)
        node = graft!(tree, TreeNode(; tau = τ), node)
        _ladder_tree!(tree, node, n-1, T-τ, τ)
    else
        label!(tree, node, "$n")
    end
    return nothing
end
