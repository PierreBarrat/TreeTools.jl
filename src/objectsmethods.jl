export node2tree, tree_findlabel, node_findlabel, node_findkey, node_find_leafkey, node_findkey_safe, share_labels
export node_clade, node_leavesclade, node_leavesclade_labels, tree_clade, tree_leavesclade, isclade, node_findroot
export lca, node_depth, node_divtime, node_ancestor_list, isancestor


###############################################################################################################
################################# Trees from nodes, finding labels, ... #######################################
###############################################################################################################


"""
	node2tree(root::TreeNode)

Create a `Tree` object from `root`. Keys are integers. 
"""
function node2tree(root::TreeNode{T} where T)
	tree = Tree(root)
	key = 1
	leafkey = 1
	node2tree_addnode!(tree, root, key, leafkey)
	return tree
end

"""
	node2tree_addnode!(tree::Tree, node::TreeNode, key::Int64 ; addchildren = true)

Add existing `node::TreeNode` to `tree::Tree` using `key`. Recursively add children of `node` if `addchildren` is true. 
Return new value of `key` to add further children to `tree`.  
If `node` is a leaf node, also add it to `tree.leaves` with key `leafkey`. Return new value of `leafkey`. 
"""
function node2tree_addnode!(tree::Tree, node::TreeNode, key::Int64, leafkey::Int64; addchildren = true)
	if in(key, keys(tree.nodes)) || in(leafkey, keys(tree.leaves))
		error("Trying to add node to an already existing key.")
	else
		tree.nodes[key] = node
		tree.lnodes[node.label] = node
		if node.isleaf
			tree.leaves[leafkey] = node
			tree.lleaves[node.label] = node
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
	name_nodes!(t::Tree)

Give a label to label-less nodes in `t`. 
"""
function name_nodes!(t::Tree)
	name_nodes!(t.root, collect(keys(t.lnodes)))
end
function name_nodes!(r::TreeNode, labels ; i = 0)
	ii = i
	if r.isleaf && isempty(r.label)
		@warn "Label-less leaf node!"
	end
	if isempty(r.label)
		while in("NODE_$ii", labels)
			ii += 1
		end
		r.label = "NODE_$ii"
		ii += 1
		for c in r.child
			ii = name_nodes!(c, labels, i = ii)
		end
	end
	return ii
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
	node_find_leafkey(node, tree)

Find leafkey corresponding to `node` in `tree`.  
Return value is `nothing` if `node` is not found. --> not type stable. 
"""
function node_find_leafkey(node, tree)
	if !node.isleaf
		return nothing
	end
	for i in keys(tree.leaves)
		if node == tree.leaves[i]
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
	share_labels(tree1, tree2)

Check if `tree1` and `tree2` share the same labels for leaf nodes. 
"""
function share_labels(tree1, tree2)
	l1 = Set(l for l in keys(tree1.lleaves))
	l2 = Set(l for l in keys(tree2.lleaves))
	return l1 ==  l2
end


###############################################################################################################
################################################### Clades ####################################################
###############################################################################################################

"""
	node_clade(root::TreeNode)

Find and return clade corresponding to all descendants of `root`. 
"""
function node_clade(root::TreeNode)
	if root.isleaf
		return [root]
	end
	clade = [root]
	for c in root.child
		append!(clade, node_clade(c))
	end
	return clade
end


"""
	node_clade_labels(root::TreeNode)

Find and return labels of nodes in clade corresponding to all descendants of `root`. 
"""
function node_clade_labels(root::TreeNode)
	if root.isleaf
		return [root.label]
	end
	clade = [root.label]
	for c in root.child
		append!(clade, node_clade(c))
	end
	return clade
end

"""
	node_leavesclade(root::TreeNode)

Find and return clade corresponding to all descendants of `root` that are leaves. 
"""
function node_leavesclade(root::TreeNode)
	if root.isleaf
		return [root]
	end
	clade = Array{TreeNode,1}(undef, 0)
	for c in root.child
		append!(clade, node_leavesclade(c))
	end
	return clade
end

"""
	node_leavesclade_labels(root::TreeNode)

Find and return labels of nodes in clade corresponding to all descendants of `root` that are leaves. 
"""
function node_leavesclade_labels(root::TreeNode)
	if root.isleaf
		return [root.label]
	end
	clade = Array{String}(undef,0)
	for c in root.child
		append!(clade, node_leavesclade_labels(c))
	end
	return clade
end

"""
	tree_clade(tree::Tree, key)

Find and return keys of clade corresponding to all descendants of `tree.nodes[key]`.
"""
function tree_clade(tree::Tree, key)
	cl = node_clade(tree.nodes[key])
	out = map(x->node_findkey(x, tree), cl)
	return out
end

"""
	tree_leavesclade(tree::Tree, key)

Find and return leaves keys of clade corresponding to all leaves descendants of `tree.nodes[key]`.
"""
function tree_leavesclade(tree::Tree, key)
	cl = node_leavesclade(tree.nodes[key])
	return map(x->node_find_leafkey(x, tree), cl)
end

"""
	node_findroot(node::TreeNode ; maxdepth=1000)

Return root of the tree to which `node` belongs.
"""
function node_findroot(node::TreeNode ; maxdepth=1000)
	temp = node
	it = 0
	while !temp.isroot || it>maxdepth
		temp = temp.anc
		it += 1 
	end
	if it>maxdepth
		@error "Could not find root after $maxdepth iterations."
	end
	return temp
end

"""
"""
function node_ancestor_list(node::TreeNode)
	list = [node.label]
	a = node
	while !a.isroot
		push!(list, a.anc.label)
		a = a.anc
	end
	return list
end

"""
	isclade(nodelist)

Check if `nodelist` is a clade. All nodes in `nodelist` should be leaves.  
"""
function isclade(nodelist)
	out = true
	if !mapreduce(x->x.isleaf, *, nodelist, init=true)
		# verbose && println("F")
		out = false
	else
		claderoot = lca(nodelist)
		clade = node_leavesclade_labels(claderoot)
		# Now, checking if `clade` is the same as `nodelist` 
		for c in clade
			flag = false
			for n in nodelist
				if n.label==c
					flag = true
					break
				end
			end
			if !flag
				out = false
				break
			end
		end
	end
	return out
end

"""
	find_clades(tree, label_list)

Find the set of clades for which leaves are exactly `label_list`. 
"""
function find_clades(tree, label_list)	
	r = lca([tree.lleaves[l] for l in label_list])
	cr = node_leavesclade_labels(r)
	if issetequal(cr, label_list) # `label_list` is the clade of `r`
		return [label_list]
	else # Go up from ll[1] and get the biggest possible clade
		ll = copy(label_list)
		return find_clades_!(ll, tree)
	end
end
function find_clades_!(list, tree)
	cl = []
	while !isempty(list)
		tmp = []
		r = tree.lleaves[list[1]]
		rflag = true
		idx = [1]
		while rflag # Go up from r as long as we can
			r = r.anc
			cr = node_leavesclade_labels(r)
			if !issubset(cr, list)
				rflag = false
			else
				idx = findall(x->in(x,cr),list) # Which elements of list are in cr
			end
		end
		push!(cl, list[idx])
		deleteat!(list, idx)
	end
	return cl
end


function find_clades!(r, nlist)

end

###############################################################################################################
######################################## LCA, divtime, ... ####################################################
###############################################################################################################
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
	lca(nodelist)

Find the common ancestor of all nodes in `nodelist`. `nodelist` is an iterable collection of `TreeNode` objects. 
"""
function lca(nodelist)
	# ca = nodelist[1]
	# Getting any element to start with
	ca = first(nodelist)
	for node in nodelist
		if !isancestor(ca, node)
			ca = lca(ca, node)
		end
	end
	return ca
end

"""
	isancestor(a:::TreeNode, node::TreeNode)

Check if `a` is an ancestor of `node`.
"""
function isancestor(a::TreeNode, node::TreeNode)
	if a==node
		return true
	else
		if node.isroot
			return false
		else
			return isancestor(a, node.anc)
		end
	end
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
	node_divtime(i_node::TreeNode, j_node::TreeNode)

Compute divergence time between `i_node` and `j_node` by summing the `TreeNode.data.tau` values. 
"""
function node_divtime(i_node::TreeNode, j_node::TreeNode)
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
