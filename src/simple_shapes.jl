function star_tree(n::Integer, τ::Real)
    tree = Tree(TreeNode(; label="root"))
    for i in 1:n
        graft!(tree, TreeNode(; label="i", tau=τ), "root"; graft_on_leaf=true)
    end
    return tree
end
