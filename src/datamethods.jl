export lca, node_depth, node_divtime, tree_cladeid_leaves

"""
	lca(i_node::TreeNode, j_node::TreeNode)

Find and return lowest common ancestor of `i_node` and `j_node`.  
Idea is to go up in the tree in an asymmetric way on the side of the deeper node, until both are at equal distance from root. Then, problem is solved by going up in a symmetric way. (https://stackoverflow.com/questions/1484473/how-to-find-the-lowest-common-ancestor-of-two-nodes-in-any-binary-tree/6183069#6183069)
"""
function lca(i_node::TreeNode, j_node::TreeNode)

	if i_node.isroot 
		return i_node
	elseif j_node.isroot
		return j_node
	end

	ii_node = i_node
	jj_node = j_node

	di = node_depth(ii_node)
	dj = node_depth(jj_node)
	while di != dj
		if di > dj
			ii_node = ii_node.anc
			di -=1
		else
			jj_node = jj_node.anc
			dj -=1
		end
	end
	while ii_node != jj_node
		ii_node = ii_node.anc
		jj_node = jj_node.anc
	end
	return ii_node
end

"""
	node_depth(node::TreeNode)

Distance from `node` to root. 
"""
function node_depth(node::TreeNode)
	d = 0
	_node = node
	while !_node.isroot
		_node = _node.anc
		d += 1
	end 
	return d
end

"""
"""
function node_divtime(i_node, j_node)
	a_node = lca(i_node, j_node)
	tau = 0
	ii_node = i_node
	jj_node = j_node
	while ii_node != a_node
		tau += ii_node.data.tau
		ii_node = ii_node.anc
	end
	while jj_node != a_node
		tau += jj_node.data.tau
		jj_node = jj_node.anc
	end
	return tau
end

"""
"""
function tree_cladeid_leaves(tree, rootkey)
	cladekeys = Array{keytype(fieldtype(Tree, :nodes)), 1}(undef, 0)
	for c in tree.nodes[rootkey].child
		append!(cladekeys, tree_cladeid_leaves(tree, node_findkey_safe(c, tree) ))
	end
	if tree.nodes[rootkey].isleaf
		push!(cladekeys, rootkey)
	end
	return cladekeys
end

