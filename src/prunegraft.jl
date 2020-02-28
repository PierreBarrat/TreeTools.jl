export prunenode!, prunenode, graftnode!, delete_node!, delete_null_branches!, remove_internal_singletons, prunesubtree!


"""
	prunenode!(node::TreeNode)

Prune node `node` by detaching it from its ancestor. Return pruned `node` and the root of its ancestor. The whole tree is modified.
"""
function prunenode!(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: no op."
		return node, TreeNode()
	end
	anc = node.anc
	for (i,c) in enumerate(anc.child)
		if c == node
			splice!(anc.child,i)
			break
		end
	end
	if isempty(anc.child)
		anc.isleaf = true
	end
	node.anc = nothing
	node.isroot = true
	return node, node_findroot(anc)
end

"""
	prunenode(node::TreeNode)

Prune node `node` by detaching it from its ancestor. Return pruned `node` and previous root `r`. The tree defined by `node` is copied before the operation, and therefore not modified. 
"""
function prunenode(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: no op."
		node_ = deepcopy(node)
		return node_, node_
	end
	node_ = deepcopy(node)
	r = node_findroot(node_)
	anc = node_.anc
	for (i,c) in enumerate(anc.child)
		if c == node_
			splice!(anc.child,i)
			break
		end
	end
	node_.anc = nothing
	node_.isroot = true
	return node_, r
end

"""
	prunenode(t::Tree, label::Vararg{String})

Prune node `t.lnodes[label]` from `t` for all `label`. Return pruned copy of `t`.
"""
function prunenode(t::Tree, label::Vararg{String} ; propagate=true)
	return prunenode(t, collect(label), propagate=propagate)
end


"""
	prunenodes(tree, labels)

Prune nodes corresponding to labels in `labels`. 
"""
function prunenode(tree, labels ; propagate=true)
	out = deepcopy(tree)
	for l in labels
		propagate ? prunenode_!(out.lnodes[l]) : prunenode!(out.lnodes[l])
	end
	out = node2tree(out.root)
end

"""
"""
function prunenode_!(node)
	if length(node.anc.child) == 1
		prunenode_!(node.anc)
	else
		prunenode!(node)
	end
end

"""
	prunesubtree!(tree, labellist)

Prune and return subtree corresponding to the MRCA of labels in `labellist`, as well as its previous direct ancestor. 
# Warning
`TreeNode` objects contained in `tree` are modified, but `tree` is *not* re-indexed after the pruning. It is therefore necessary to call `node2tree(tree.root)` after this.
"""
function prunesubtree!(tree, labellist)
	r = lca([tree.lnodes[x] for x in labellist])
	a = r.anc
	if !r.isroot
		subtree = node2tree(prunenode!(r)[1])
	else
		@warn "Trying to prune root"
	end
	return subtree, a
end

"""
	remove_internal_singletons!(tree)

Remove nodes with one child. Return a new tree. Root node is left as is.

## Warning
The `TreeNode` constituting `tree` are modified in the process. This means `tree` will be be modifier as well in an uncontrolled manner.  
"""
function remove_internal_singletons!(tree)
	root = tree.root
	for n in values(tree.nodes)
		if !n.isleaf && !n.isroot
			if length(n.child) == 1
				delete_node!(n, ptau=true)
			end
		end
	end
	return node2tree(root)
end


"""
	graftnode!(r::TreeNode, n::TreeNode ; tau=n.data.tau)

Graft `n` on `r`. 
"""
function graftnode!(r::TreeNode, n::TreeNode ; tau=n.data.tau)
	if !n.isroot || n.anc != nothing
		@error "Trying to graft non-root node."
	end
	push!(r.child, n)
	r.isleaf = false
	n.anc = r
	n.isroot = false
	n.data.tau = tau
end

"""
	delete_node!(node::TreeNode; ptau=false)

Delete `node` from the tree. If it is an internal node, its children are regrafted on `node.anc`. Returns the new `node.anc`.  If `ptau`, branch length above `node` is added to the regrafted branch. Otherwise, the regrafted branch's length is unchanged. 
"""
function delete_node!(node::TreeNode; ptau=false)
	if node.isroot
		@error "Cannot delete root node"
		error()
	end
	out = node.anc
	if node.isleaf
		prunenode!(node)
	else
		base_tau = node.data.tau
		child_list = []
		for c in node.child
			push!(child_list, c)
		end
		for c in child_list
			nc = prunenode!(c)[1]
			graftnode!(node.anc, nc, tau = (base_tau*ptau + nc.data.tau))
		end
		prunenode!(node)
	end
	return out
end

"""
	delete_null_branches!(node ; threshold = 1e-10)

Delete internal node with null branch length.
- If `node` needs not be deleted, call `delete_null_branches!` on its children
- If need be, call `delete_null_branches!` on `node.anc.child`
"""
function delete_null_branches!(node; threshold = 1e-10)
	if !node.isleaf 	
		if !ismissing(node.data.tau) && node.data.tau < threshold && !node.isroot
			nr = delete_node!(node)
			for c in nr.child
				delete_null_branches!(c, threshold=threshold)
			end
		else
			for c in node.child
				delete_null_branches!(c,threshold=threshold)
			end
		end
	end
end


"""
	reroot!(node::TreeNode ; newroot::Union{TreeNode,Nothing}=nothing)
- If `node.isroot`, 
- Else if `newroot == nothing`, reroot the tree defined by `node` at `node`. Call `reroot!(node.anc, node)`. 
- Else, call `reroot!(node.anc, node)`, then change the ancestor of `node` to be `newroot`. 
"""
function reroot!(node::Union{TreeNode,Nothing}; newroot::Union{TreeNode, Nothing}=nothing)
	# Breaking cases
	if node.anc == nothing || node.isroot
		if !(node.anc == nothing && node.isroot) 
			@warn "There was a problem with input tree: previous root node has an ancestor."
		elseif newroot != nothing
			i = findfirst(c->c.label==newroot.label, node.child)
			splice!(node.child, i)
			node.anc = newroot
			node.data.tau = newroot.data.tau
			node.isroot = false
		end
	else # Recursion
		if newroot == nothing
			if node.isleaf
				@warn "Rooting on a leaf node..."
			end
			node.isroot = true
			reroot!(node.anc, newroot=node)
			push!(node.child, node.anc)
			node.anc = nothing
			node.data.tau = missing
		else
			i = findfirst(c->c.label==newroot.label, node.child)
			splice!(node.child, i)
			reroot!(node.anc, newroot=node)
			push!(node.child, node.anc)
			node.anc = newroot
			node.data.tau = newroot.data.tau
		end
	end
end


