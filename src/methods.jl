###############################################################################################################
################################# Trees from nodes, etc...			    #######################################
###############################################################################################################


"""
	node2tree(root::TreeNode{T}; force_new_labels=false)

Create a `Tree` object from `root`.
"""
function node2tree(root::TreeNode{T}; force_new_labels=false) where T
	tree = Tree(root, Dict{String, TreeNode{T}}(), Dict{String, TreeNode{T}}())
	node2tree_addnode!(tree, root; force_new_labels)
	return tree
end

function node2tree!(tree::Tree, root::TreeNode; force_new_labels=false)
	tree.root = root
	tree.lnodes = Dict{String, TreeNode}()
	tree.lleaves = Dict{String, TreeNode}()
	node2tree_addnode!(tree, root; force_new_labels)
end

"""
	function node2tree_addnode!(tree::Tree, node::TreeNode; safe = true)

Add existing `node::TreeNode` to `tree::Tree`. Recursively add children of `node` if `addchildren` is true.
If `node` is a leaf node, also add it to `tree.lleaves`.
"""
function node2tree_addnode!(tree::Tree, node::TreeNode; force_new_labels=false)
	# if node.isleaf && haskey(tree.lnodes, node.label)
	# 	error("Leaf $(node.label) appears twice in the tree.")
	# end
	if isempty(node.label) || (haskey(tree.lnodes, node.label) && force_new_labels)
		set_unique_label!(node, tree; delim="__")
	end

	if haskey(tree.lnodes, node.label)
		error("Node $(node.label) appears twice in tree. Use `force_new_labels`.")
	end
	tree.lnodes[node.label] = node
	if node.isleaf
		tree.lleaves[node.label] = node
	end
	for c in node.child
		node2tree_addnode!(tree, c; force_new_labels)
	end
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
	share_labels(tree1, tree2)

Check if `tree1` and `tree2` share the same labels for leaf nodes.
"""
function share_labels(tree1, tree2)
	l1 = Set(l for l in keys(tree1.lleaves))
	l2 = Set(l for l in keys(tree2.lleaves))
	return l1 ==  l2

end

"""
	Base.map!(f, r::TreeNode)

Call `f(n)` on each node in the clade below `r`, `r` included. Return `nothing`.
"""
function Base.map!(f, r::TreeNode)
	for c in r.child
		map!(f, c)
	end
	f(r)
	return nothing
end

"""
	Base.count(f, r::TreeNode)

Call `f(n)` on each node in the clade below `r` and return the number of time it returns
  `true`.
"""
function Base.count(f, r::TreeNode)
	c = _count(f, 0, r)
	return c
end
Base.count(f, t::Tree) = count(f, t.root)

function _count(f, c, r)
	if f(r)
		c += 1
	end
	for n in r.child
		c += _count(f, 0, n)
	end
	return c
end
###############################################################################################################
##################################### Copy tree with different NodeData #######################################
###############################################################################################################

function _copy(r::TreeNode, ::Type{T}) where T <: TreeNodeData
	!r.isroot && error("Copying non-root node.")
	data = T()
	child = if r.isleaf
		Array{TreeNode{T}, 1}(undef, 0)
	else
		Array{TreeNode{T}, 1}(undef, length(r.child))
	end
	cr = TreeNode(
		data;
		anc=nothing, isleaf=r.isleaf, isroot=true, label=r.label, tau=r.tau, child=child
	)
	for (i,c) in enumerate(r.child)
		_copy!(cr, c, i)
	end
	return cr
end
"""
	_copy!(an::TreeNode{T}, n::TreeNode) where T <: TreeNodeData

Create a copy of `n` with node data type `T` and add it to the children of `an`.
"""
function _copy!(an::TreeNode{T}, n::TreeNode, i) where T <: TreeNodeData
	data = T()
	child = if n.isleaf
		Array{TreeNode{T}, 1}(undef, 0)
	else
		Array{TreeNode{T}, 1}(undef, length(n.child))
	end
	cn = TreeNode(
		data;
		anc=an, isleaf=n.isleaf, isroot=n.isroot, label=n.label, tau=n.tau, child=child
	)
	# Adding `cn` to the children of its ancestor `an`
	an.child[i] = cn
	# Copying children of `n`
	for (i,c) in enumerate(n.child)
		_copy!(cn, c, i)
	end

	return nothing
end
"""
	copy(t::Tree, T::DataType = EmptyData)
"""
Base.copy(t::Tree, T::DataType = EmptyData) = node2tree(_copy(t.root, T))

Base.convert(::Type{Tree{EmptyData}}, t::Tree) = copy(t, EmptyData)

###############################################################################################################
################################################### Clades ####################################################
###############################################################################################################


"""
	node_findroot(node::TreeNode ; maxdepth=1000)

Return root of the tree to which `node` belongs.
"""
function node_findroot(node::TreeNode ; maxdepth=1000)
	temp = node
	it = 0
	while !temp.isroot && it <= maxdepth
		temp = temp.anc
		it += 1
	end
	if it > maxdepth
		@error("Could not find root after $maxdepth iterations.")
		error()
	end
	return temp
end

"""
	node_ancestor_list(node::TreeNode)

Return array of all ancestors of `node` up to the root.
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
	isclade(nodelist::AbstractArray{<:AbstractString}, t::Tree)

Check if `nodelist` is a clade. All nodes in `nodelist` should be leaves.
"""
function isclade(nodelist; safe=true)
	out = true
	if safe && !mapreduce(x->x.isleaf, *, nodelist, init=true)
		out = false
	else
		claderoot = lca(nodelist)
		# Now, checking if `clade` is the same as `nodelist`
		for c in POTleaves(claderoot)
			flag = false
			for n in nodelist
				if n.label==c.label
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
function isclade(nodelist::AbstractArray{<:AbstractString}, t::Tree)
	return isclade([t.lnodes[n] for n in nodelist])
end



###############################################################################################################
######################################## LCA, divtime, ... ####################################################
###############################################################################################################
"""
	node_depth(node::TreeNode)

Topologic distance from `node` to root.
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
function lca(nodelist::Vararg{<:TreeNode})
	# Getting any element to start with
	ca = first(nodelist)
	for node in nodelist
		if !isancestor(ca, node)
			ca = lca(ca, node)
		end
	end
	return ca
end
lca(nodelist) = lca(nodelist...)
"""
	lca(t::Tree, labels::Array{<:AbstractString,1})
	lca(t::Tree, labels...)
"""
function lca(t::Tree, labels)
	ca = t.lnodes[first(labels)]
	for l in labels
		if !isancestor(ca, t.lnodes[l])
			ca = lca(ca, t.lnodes[l])
		end
	end
	return ca
end
lca(t::Tree, labels::Vararg{<:AbstractString}) = lca(t, collect(labels))

"""
	blca(nodelist::Vararg{<:TreeNode})

Return list of nodes just below `lca(nodelist)`. Useful for introducing splits in a tree.
"""
function blca(nodelist::Vararg{<:TreeNode})
	r = lca(nodelist...)
	out = []
	for n in nodelist
		a = n
		while a.anc != r
			a = a.anc
		end
		push!(out, a)
	end
	return out
end


"""
	divtime(i_node::TreeNode, j_node::TreeNode)

Compute divergence time between `i_node` and `j_node` by summing the `TreeNode.tau` values.
"""
function divtime(i_node::TreeNode, j_node::TreeNode)
	a_node = lca(i_node, j_node)
	tau = 0.
	ii_node = i_node
	jj_node = j_node
	while ii_node != a_node
		tau += ii_node.tau
		ii_node = ii_node.anc
	end
	while jj_node != a_node
		tau += jj_node.tau
		jj_node = jj_node.anc
	end
	return tau
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
