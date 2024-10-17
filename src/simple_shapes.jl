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

"""
    ladder_tree(n[, t=missing])

Return a ladder tree with `n` leaves with total height `t`.
For 4 leaves `A, B, C, D`, this would be `(A:t,(B:2t/3,(C:t/3,D:t/3)));`.
The elementary branch length is `t/(n-1)` if `n>1`.
"""
function ladder_tree(n::Integer, T::Union{Missing, Real} = missing)
    # proceeds by recursively grafting asymetric shapes (An:(T-τ),Bn:τ) onto B_(n-1)
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

"""
    balanced_binary_tree(n::Integer, time::Union{Missing, Real} = missing)

Return a balanced binary tree of `n` nodes with all branches of length `time`.
`n` must be a power of 2.
"""
function balanced_binary_tree(n::Integer, time::Union{Missing, Real} = missing)
    if !ispow2(n)
        error("Number of nodes must be a power of 2. Instead $n")
    end


    tree = Tree()
    if n == 1
        label!(tree, tree.root, "1")
    end

    while n > 1
        id = 1
        for leaf in collect(leaves(tree)) # collect because we modify the dict
            new_leaf_1 = graft!(tree, TreeNode(tau=time), leaf; graft_on_leaf=true)
            new_leaf_2 = graft!(tree, TreeNode(tau=time), leaf; graft_on_leaf=true)
            if n == 2
                # then new_leaf will remain a leaf. Label it nicely
                label!(tree, new_leaf_1, id)
                label!(tree, new_leaf_2, id+1)
                id += 2
            end
        end
        n /= 2
    end

    return tree
end
