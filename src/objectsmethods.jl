export node2tree, tree_findlabel


"""
	prunenode!(node::TreeNode)

Prune `node` by detaching it from its ancestor. Said ancestor is removed from the tree. 
"""
function prunenode!(node::TreeNode)
	anc = node.anc
	extractnode!(anc)
	node.anc = nothing
end

"""
	extractnode!(node::TreeNode)

Extract a node with only one child from the tree. `node.child[1]` and `node.and` are connected. 
"""
function extractnode!(node::TreeNode)
	if length(node.child) > 1
		error("Cannot extract node with more than 2 children")
	elseif length(node.child) == 0
		error("Cannot extract a node without children. Those need to be pruned.")
	end
	#
	anc = node.anc
	child = node.child[1]
	# 
	for (i,c) in anc.child
		if c == node
			anc.child[i] = child
			break
		end
	end
	child.anc = anc
end

"""
	graftnode!(rootstock::TreeNode, graft::TreeNode)

Graft `graft` to `rootstock`. `rootstock` should have strictly less than 2 children for this to work. `graft` should not have any ancestor. 
"""
function graftnode!(rootstock::TreeNode, graft::TreeNode)
	if graft.anc != nothing
		error("Cannot graft an already rooted node. (graft label: $(graft.label))")
	end
	if length(rootstock.child) > 1
		error("Grafting on node with more than 1 child. Tree will no longer be binary.")
	end
	graft.anc = rootstock
	push!(rootstock.child, graft)
end

"""
	graftnode!(ancestor::TreeNode, child::TreeNode, insert::TreeNode, tau::Float64)

Insert node `insert` in the branch between `ancestor` and `child`. Time of the insertion `tau` is measured from `ancestor`.  
At the end of the insertion, `insert` only has one child `child`. 
"""
function graftnode!(ancestor::TreeNode, child::TreeNode, insert::TreeNode, tau::Float64)
	if child.anc != ancestor
		error("Attempting to insert node between two not-directly related nodes.")
	end
	if tau > child.data.tau
		error("Attempting to insert a node at a time longer than existing branch.")
	# Pruning and re-grafting `child`
	child.anc = insert
	child.data.tau = child.data.tau - tau
	insert.child = [child]
	# Grafting `insert`
	insert.anc = ancestor;
	insert.data.tau = tau
	for (i,c) in enumerate(ancestor.child)
		if c == child
			ancestor.child[i] = insert
		end
	end

	insert.isleaf = false
	insert.isroot = false
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

