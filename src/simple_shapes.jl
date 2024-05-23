"""
    star_tree(n, times)

Create a star tree with `n` leaves.
`times` can be an iterable of length `n` or a number/missing.
"""
function star_tree(n::Integer, time::Union{Missing, Real} = missing)
    return star_tree(n, Iterators.map(x -> time, 1:n))
end
function star_tree(n::Integer, time_vals)
    @assert length(time_vals) == n "Number of leaves and times must match - \
        Instead $n and $(length(time_vals))"

    tree = Tree(TreeNode(; label="root"))
    for (i, t) in enumerate(time_vals)
        graft!(tree, TreeNode(; label="$i", tau=t), "root"; graft_on_leaf=true)
    end
    return tree
end
