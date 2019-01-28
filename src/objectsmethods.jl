export node2tree, tree_findlabel, prunenode!, graftnode!, node_findlabel, node_findkey, node_findkey_safe


"""
	prunenode!(node::TreeNode)

Prune `node` by detaching it from its ancestor, and return `node`. Said ancestor is removed from the tree since it only has one child.  `node` is set to root. 
No leaf or root status can change on the main tree in this operation. 
"""
function prunenode!(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: no op."
		return node
	end
	anc = node.anc
	for (i,c) in enumerate(anc.child)
		if c == node
			splice!(anc.child, i)
			break
		end
	end
	_extractnode!(anc)
	node.anc = nothing
	node.isroot = true
	return node
end

"""
	_extractnode!(node::TreeNode)

Extract a node with only one child from the tree. `node.child[1]` and `node.anc` are connected. 
"""
function _extractnode!(node::TreeNode)
	if length(node.child) > 1
		error("Cannot extract node with more than 1 children")
	elseif length(node.child) == 0
		error("Cannot extract a node without children. Those need to be pruned.")
	end
	#
	anc = node.anc
	child = splice!(node.child, 1)
	# Linking `anc` and `child`
	for (i,c) in enumerate(anc.child)
		if c == node
			anc.child[i] = child
			break
		end
	end
	child.anc = anc
	# Handling times
	child.data.tau += node.data.tau
	child.data.n_ntmut += node.data.n_ntmut
	return nothing
end

"""
	_prunenode!(node::TreeNode)

Prune `node` by detaching it from its ancestor, and return `node`. Said ancestor is **NOT** removed from the tree.  `node` is set to root. 
No leaf or root status can change on the main tree in this operation. 
"""
function _prunenode!(node::TreeNode)
	anc = node.anc
	for (i,c) in enumerate(anc.child)
		if c == node
			splice!(anc.child, i)
			break
		end
	end
	node.anc = nothing
	node.isroot = true
	return node
end


"""
	_graftnode!(rootstock::TreeNode, graft::TreeNode)

Graft `graft` to `rootstock`. `rootstock` should have strictly less than 2 children for this to work. `graft` should not have any ancestor.  
This function does not guarantee that the tree will stay binary, since one can graft on a `rootstock` without children. 
"""
function _graftnode!(rootstock::TreeNode, graft::TreeNode)
	if graft.anc != nothing
		error("Can only graft a node without ancestors (graft label: $(graft.label)).")
	end
	if length(rootstock.child) > 1
		error("Grafting on node with more than 1 child. Tree will no longer be binary.")
	end

	graft.anc = rootstock
	push!(rootstock.child, graft)
	rootstock.isleaf = false
	graft.isroot = false
	return nothing
end

"""
	graftnode!(ancestor::TreeNode, child::TreeNode, graft::TreeNode, tau::Float64)

Graft `graft` in the branch between `ancestor` and `child`, at position `tau`. A new node `rootstock` is introduced at this position.  
Keywords: 
- `insert_label = ""`: Label of the inserted `rootstock` node. 
"""
function graftnode!(ancestor::TreeNode, child::TreeNode, graft::TreeNode, tau::Float64 ; insert_label = "")
	# Safety checks
	if child.anc != ancestor
		error("Can only graft a node on a (ancestor --> child) branch.")
	end
	if graft.anc != nothing || !graft.isroot
		error("Can only graft a node without ancestor. $(graft.label) is not root.")
	end
	if tau > child.data.tau
		error("Cannot graft at a position longer than the branch length.")
	end
	# Prune child
	child = _prunenode!(child)
	# Create rootstock
	rootstock = TreeNode(label = insert_label)
	rootstock.data.tau = tau
	# Graft rootstock on ancestor
	_graftnode!(ancestor, rootstock)
	# Graft child on rootstock
	_graftnode!(rootstock, child)
	child.data.tau = child.data.tau - tau
	# Graft graft on rootstock
	_graftnode!(rootstock, graft)
	return nothing
end

"""
	node2tree(root::TreeNode)

Create a `Tree` object from `root`. Keys are integers. 
"""
function node2tree(root::TreeNode)
	tree = Tree(root = root)
	key = 1
	leafkey = 1
	node2tree_addnode!(tree, root, key, leafkey)
	return tree
end

"""
	node2tree_addnode!(tree::Tree, node::TreeNode, key::Int64 ; addchildren = true)

Add existing `node::TreeNode` to `tree::Tree` using `key`. Recursively add children of `node` if `addchildren` is true.  
Return new value of `key` to add further children to `tree`. 
"""
function node2tree_addnode!(tree::Tree, node::TreeNode, key::Int64, leafkey::Int64; addchildren = true)
	if in(key, keys(tree.nodes)) || in(leafkey, keys(tree.leaves))
		error("Trying to add node to an already existing key.")
	else
		tree.nodes[key] = node
		if node.isleaf
			tree.leaves[leafkey] = node
		end
		if addchildren
			ckey = key + 1
			node.isleaf ? cleafkey = leafkey + 1 : cleafkey = leafkey
			for c in node.child
				ckey, cleafkey = node2tree_addnode!(tree, c, ckey, cleafkey)
			end
		end
	end
	return ckey, cleafkey
end


"""
	tree_findlabel(label::String, tree::Tree)

Find a sequence with label `label` in `tree`, and return a `(key, flag)` tuple. `key` is the key of the found sequence in `tree.nodes`. Defaults to `0` if no match is found. `flag` is `true` if a match is found, `false` otherwise. 
"""
function tree_findlabel(label::String, tree::Tree)
	for k in keys(tree.nodes)
		if tree.nodes[k].label == label
			return k, true
		end
	end
	return 0, false
end


"""
	node_findlabel(label::String, root::TreeNode ; subtree = true)

Find label in tree defined by `root`. If `subtree`, only the children of `root` are searched. Otherwise, the whole tree is searched.  

# Note
`subtree = false` is not yet implemented.
"""
function node_findlabel(label::String, root::TreeNode ; subtree = true)
	found, node = _node_findlabel(label, root)
	if !found
		@warn "Label $(label) was not found."
	end
	return node
end

"""
"""
function _node_findlabel(label::String, root::TreeNode)
	if root.label == label
		return true, root
	end
	for c in root.child
		found, out = _node_findlabel(label, c)
		if found
			return found, out
		end
	end
	return false, nothing
end

"""
	node_findkey(node, tree)

Find key corresponding to `node` in `tree`.  
Return value is `nothing` if `node` is not found. --> not type stable. 
"""
function node_findkey(node, tree)
	for i in keys(tree.nodes)
		if node == tree.nodes[i]
			return i
		end
	end
	return nothing
end

"""
	node_findkey_safe(node,  tree)

Type safe implementation of `node_findkey`. If nothing is found, an error is raised.
"""
function node_findkey_safe(node,tree)
	a = node_findkey(node,tree)
	if a == nothing
		error("Node $(node.label) was not found in tree.")
	end
	return a
end

"""
	node_findkey(node, tree)

Find key corresponding to `node` in `tree`.  
Return value is `nothing` if `node` is not found. --> not type stable. 
"""
function node_findkey(node, tree)
	for i in keys(tree.nodes)
		if node == tree.nodes[i]
			return i
		end
	end
	return nothing
end