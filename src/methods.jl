###############################################################################################################
################################# Trees from nodes, etc...			    #######################################
###############################################################################################################


"""
	node2tree(root::TreeNode{T}; label = default_tree_label(), force_new_labels=false)

Create a `Tree` object from `root` with name `label`. If `force_new_labels`, a random
string is added to node labels to make them unique.
"""
function node2tree(
	root::TreeNode{T};
	label = default_tree_label(), force_new_labels = false
) where T
	if !isroot(root)
		@warn "Creating a tree from non-root node $(root.label)."
	end
	tree = Tree(root, Dict{String, TreeNode{T}}(), Dict{String, TreeNode{T}}(), label)
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

Add existing `node::TreeNode` and all of its children to `tree::Tree`.
If `node` is a leaf node, also add it to `tree.lleaves`.

## Note on labels
- throw error if `node.label` already exists in `tree`. Used `force_new_labels` to append
	a random string to label, making it unique.
- if `node.label` can be
	interpreted as a bootstrap value, a random string is added to act as an actual label.
	See `?TreeTools.isbootstrap` for labels interpreted as bootstrap.
	This is only applied to internal nodes.
"""
function node2tree_addnode!(tree::Tree, node::TreeNode; force_new_labels=false)
	isbb = !isleaf(node) && isbootstrap(node.label)
	if isempty(node.label) || (in(node, tree) && force_new_labels) || isbb
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
	isbootstrap(label::AbstractString)

`label` is interpreted as a confidence value if `label` can be parsed as a
decimal number (*e.g.* `"87"`, `"100"`, `"76.8"`, `"0.87"`" or `"1.0"`)

Multiple confidence values separated by a `/` are also interpreted as such.
- `"87.7/32"` will be interpreted as a confidence value
- `"87.7/cool_node"` will not
"""
function isbootstrap(label::AbstractString)
	elements = split(label, '/')
	for e in elements
		if isnothing(tryparse(Float64, e))
			return false
		end
	end
	return true
end


"""
	parse_bootstrap(label::AbstractString)

**NOT IMPLEMENTED YET**

Parse and return confidence value for `label`. Return `missing` if nothing could be parsed.
`label` is interpreted as a bootstrap value if
- `label` can be parsed as a <= 100 integer (*e.g.* `"87"` or `"100"`)
- `label can be parsed as a <= 1 decimal number (*e.g.* `"0.87"`" or `"1.0"`)
If label is of one of these forms and followed by a string of the form `__NAME`, it is also
parsed.
"""
function parse_bootstrap(label::AbstractString)
	return missing
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
	Base.map!(f, t::Tree)
	Base.map!(f, r::TreeNode)

In the `Tree` version, call `f(n)` on all nodes of `t`.
In the `TreeNode` version, call `f(n)` on each node in the clade below `r`, `r` included.
Useful if `f` changes its input. Return `nothing`.
"""
function Base.map!(f, r::TreeNode)
	for c in r.child
		map!(f, c)
	end
	f(r)
	return nothing
end
Base.map!(f, t::Tree) = map!(f, t.root)

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
	data = _copy_data(T, r)
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
	data = _copy_data(T, n)
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
_copy_data(::Type{T}, n::TreeNode{T}) where T <: TreeNodeData = deepcopy(n.data)
_copy_data(::Type{T}, n::TreeNode) where T <: TreeNodeData = T()

"""
	copy(t::Tree; force_new_tree_label = false, label=nothing)

Make a copy of `t`. The copy can be modified without changing `t`. By default `tree.label`
is also copied. If this is not desired `force_new_tree_label=true` will create create a copy
of the tree with a new label. Alternatively a `label` can be set with the `label` argument.
"""
function Base.copy(t::Tree{T}; force_new_tree_label = false, label=nothing) where T <: TreeNodeData
	if force_new_tree_label
		node2tree(_copy(t.root, T))
	else
		node2tree(_copy(t.root, T), label = isnothing(label) ? t.label : label)
	end
end

Base.convert(::Type{Tree{T}}, t::Tree{T}) where T <: TreeNodeData = t
Base.convert(::Type{Tree{T}}, t::Tree; label=t.label) where T <: TreeNodeData = node2tree(_copy(t.root, T), label=label)

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
	distance(t::Tree, n1::AbstractString, n2::AbstractString; topological=false)
	distance(n1::TreeNode, n2::TreeNode; topological=false)

Compute branch length distance between `n1` and `n2` by summing the `TreeNode.tau` values.
If `topological`, the value `1` is summed instead of `TreeNode.tau`.
"""
function distance(i_node::TreeNode, j_node::TreeNode; topological=false)
	a_node = lca(i_node, j_node)
	tau = 0.
	ii_node = i_node
	jj_node = j_node
	while ii_node != a_node
		tau += topological ? 1. : ii_node.tau
		ii_node = ii_node.anc
	end
	while jj_node != a_node
		tau += topological ? 1. : jj_node.tau
		jj_node = jj_node.anc
	end
	return tau
end
function distance(t::Tree, n1::AbstractString, n2::AbstractString; topological=false)
	return distance(t.lnodes[n1], t.lnodes[n2]; topological)
end

# for convenience with old functions -- should be removed eventually
divtime(i_node, j_node) = distance(i_node, j_node)

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


###############################################################################################################
######################################## Topology: reroot, binarize, ladderize... ####################################################
###############################################################################################################


"""
	binarize!(t::Tree; τ=0.)

Make `t` binary by adding arbitrary internal nodes with branch length `τ`.
"""
function binarize!(t::Tree; mode = :balanced, τ = 0.)
	# I would like to implement `mode = :random` too in the future
	z = binarize!(t.root; mode, τ)
	node2tree!(t, t.root)
	return z
end
function binarize!(n::TreeNode{T}; mode = :balanced, τ = 0.) where T
	z = 0
	if length(n.child) > 2
		c_left, c_right = _partition(n.child, mode)
		for part in (c_left, c_right)
			if length(part) > 1
				z += 1
				nc = TreeNode(T(), label=make_random_label("BINARIZE"))
				for c in part
					prunenode!(c)
					graftnode!(nc, c)
				end
				graftnode!(n, nc; tau=τ)
			end
		end
	end

	for c in n.child
		z += binarize!(c; mode, τ)
	end

	return z
end
function _partition(X, mode)
	# for now mode==:balanced all the time, so it's simple
	L = length(X)
	half = div(L,2) + mod(L,2)
	return X[1:half], X[(half+1):end]
end

#=
Reroot the tree to which `node` belongs at `node`.
- If `node.isroot`,
- Else if `newroot == nothing`, reroot the tree defined by `node` at `node`. Call `reroot!(node.anc; node)`.
- Else, call `reroot!(node.anc; node)`, then change the ancestor of `node` to be `newroot`.
=#
function reroot!(node::Union{TreeNode,Nothing}; newroot::Union{TreeNode, Nothing}=nothing)
	# Breaking cases
	if node.anc == nothing || node.isroot
		if !(node.anc == nothing && node.isroot)
			@warn "There was a problem with input tree: previous root node has an ancestor."
		elseif newroot != nothing
			i = findfirst(c->c.label==newroot.label, node.child)
			deleteat!(node.child, i)
			node.anc = newroot
			node.tau = newroot.tau
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
			node.tau = missing
		else
			i = findfirst(c->c.label==newroot.label, node.child)
			deleteat!(node.child, i)
			reroot!(node.anc, newroot=node)
			push!(node.child, node.anc)
			node.anc = newroot
			node.tau = newroot.tau
		end
	end
end
"""
	reroot!(tree::Tree, node::AbstractString)

Reroot `tree` at `tree.lnodes[node]`.
"""
function reroot!(tree::Tree, node::AbstractString)
	reroot!(tree.lnodes[node])
	tree.root = tree.lnodes[node]

	return nothing
end

"""
	ladderize!(t::Tree)

Ladderize `t` by placing nodes with largest clades left in the newick string.
"""
ladderize!(t::Tree) = ladderize!(t.root)
function ladderize!(n::TreeNode)
	function _isless(v1::Tuple{Int, String}, v2::Tuple{Int, String})
		if (v1[1] < v2[1]) || (v1[1] == v2[1] && v1[2] < v2[2])
			return true
		else 
			return false
		end
	end
	if n.isleaf
		return (1, n.label)
	else
		rank = Array{Any}(undef, length(n.child))
		for (k, c) in enumerate(n.child)
			rank[k] = ladderize!(c)
		end
		n.child = n.child[sortperm(rank; lt= _isless)]

		return sum([r[1] for r in rank]), n.label
	end

	return nothing
end


###############################################################################################################
######################################## Other ####################################################
###############################################################################################################


"""
	branches_of_spanning_tree(t::Tree, leaves...)

Return the set of branches of `t` spanning `leaves`.  The output is a `Vector{String}`
containing labels of nodes. The branch above each of these nodes is in the spanning tree.
"""
function branches_in_spanning_tree(t::Tree{T}, leaves::Vararg{String}) where T
	R = lca(t, leaves...) # root of the spanning tree
	visited = Dict{String, Bool}()
	for n in leaves
		a = t[n]
		while !haskey(visited, a.label) && a != R
			visited[a.label] = true
			a = t[a.label].anc
		end
	end
	return collect(keys(visited))
end
branches_in_spanning_tree(t, leaves::Vector{String}) = branches_in_spanning_tree(t, leaves...)
function branches_in_spanning_tree(t, leaves::Vararg{TreeNode})
	return branches_in_spanning_tree(t, Iterators.map(x->x.label, leaves)...)
end

