export prunenode!, prunenode, graftnode!, delete_node!, delete_null_branches!, prunenodes, remove_internal_singletons


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

Prune node `node` by detaching it from its ancestor. Return pruned `node`. The tree defined by `node` is copied before the operation, and therefore not modified. 
"""
function prunenode(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: no op."
		return node
	end
	node_ = deepcopy(node)
	anc = node_.anc
	for (i,c) in enumerate(anc.child)
		if c == node_
			splice!(anc.child,i)
			break
		end
	end
	node_.anc = nothing
	node_.isroot = true
	return node_
end

"""
	prunenodes(tree, labellist)

Prune nodes corresponding to labels in `labellist`. 
"""
function prunenodes(tree, labellist)
	out = deepcopy(tree)
	for l in labellist
		prunenode_!(out.lnodes[l])
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
"""
function remove_internal_singletons(tree)
	root = tree.root
	for n in values(tree.nodes)
		if !n.isleaf && !n.isroot
			if length(n.child) == 1
				delete_node!(n)
			end
		end
	end
	return node2tree(root)
end


"""
	graftnode!(r, n)

Graft `n` on `r`. 
"""
function graftnode!(r, n ; tau=n.data.tau)
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
	delete_node(node)

Delete `node` from the tree. If it is an internal node, its children are regrafted on `node.anc`. Returns the new `node.anc`. 
"""
function delete_node!(node)
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
			graftnode!(node.anc, nc, tau = (base_tau + nc.data.tau))
		end
		prunenode!(node)
	end
	return out
end

"""
	delete_null_branches!(node)

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