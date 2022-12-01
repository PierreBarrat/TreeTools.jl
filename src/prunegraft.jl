"""
	prunenode!(node::TreeNode)

Prune node `node` by detaching it from its ancestor.
Return pruned `node` and its previous ancestor.
"""
function prunenode!(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: aborting"
		return node, TreeNode()
	end
	anc = node.anc
	for (i,c) in enumerate(anc.child)
		if c == node
			deleteat!(anc.child,i)
			break
		end
	end
	if isempty(anc.child)
		anc.isleaf = true
	end
	node.anc = nothing
	node.isroot = true
	return node, anc
end

"""
	prunenode(node::TreeNode)

Prune node `node` by detaching it from its ancestor.
Return pruned `node` and previous root `r`.
The tree defined by `node` is copied before the operation and is not modified.
"""
function prunenode(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: aborting"
		node_ = deepcopy(node)
		return node_, node_
	end
	node_ = deepcopy(node)
	r = node_findroot(node_)
	anc = node_.anc
	for (i,c) in enumerate(anc.child)
		if c == node_
			deleteat!(anc.child,i)
			break
		end
	end
	node_.anc = nothing
	node_.isroot = true
	return node_, r
end

"""
	graftnode!(r::TreeNode, n::TreeNode ; tau=n.tau)

Graft `n` on `r`.
"""
function graftnode!(r::TreeNode, n::TreeNode; tau=n.tau)
	if !n.isroot || n.anc != nothing
		@error "Trying to graft non-root node $(n)."
	end
	push!(r.child, n)
	r.isleaf = false
	n.anc = r
	n.isroot = false
	n.tau = tau
	return nothing
end


"""
	prunesubtree!(tree, r::TreeNode)
	prunesubtree!(tree, labellist)

Prune and subtree corresponding to the MRCA of labels in `labellist`.
Return the root of the subtree as a `TreeNode` as well as its previous direct ancestor.
"""
function prunesubtree!(tree, labellist; clade_only=true)
	if clade_only && !isclade(labellist, tree)
		error("Can't prune non-clade $labellist")
	end
	r = lca(tree, labellist)
	return prunesubtree!(tree, r)
end

function prunesubtree!(tree, r::TreeNode; remove_singletons=true)
	if r.isroot
		@error "Trying to prune root"
	end

	a = r.anc
	delnode(n) = begin
		delete!(tree.lnodes, n.label)
		if n.isleaf
			delete!(tree.lleaves, n.label)
		end
	end
	map!(delnode, r)
	prunenode!(r)
	if remove_singletons
		remove_internal_singletons!(tree, ptau=true)
	end
	return r, a
end

function prune!(t, r; return_tree=true, kwargs...)
	r, a = prunesubtree!(t, r; kwargs...)
	return return_tree ? node2tree(r) : r
end


"""
	graft!(tree::Tree, n, r; graft_on_leaf=false)

Graft `n` onto `r`.
`r` can be a label or a `TreeNode`, and should belong to `tree`.
`n` can be a node label, a `TreeNode`, or a `Tree`.
In the latter case, `n` will be *copied* before being grafted.
None of the nodes of the subtree of `n` should belong to `tree`.

If `r` is a leaf and `graft_on_leaf` is set to `false` (default), will raise an error.
"""
function graft!(
	t::Tree, n::TreeNode, r::TreeNode;
	graft_on_leaf=false, tau = branch_length(n),
)
	# checks
	if !graft_on_leaf && isleaf(r)
		error("Cannot graft: node $r is a leaf (got `graft_on_leaf=false`")
	elseif !isroot(n) && !isnothing(ancestor(n))
		error("Cannot graft non-root node $(label(n))")
	end

	# checking that the subtree defined by `n` is not in `t`
	for c in POT(n)
		if in(c, t)
			error("Cannot graft: some nodes in subtree of $(label(n)) are already part of tree $(label(t))")
		end
	end

	# Handling tree dicts
	isleaf(r) && delete!(t.lleaves, label(r))
	for c in POT(n)
		t.lnodes[label(c)] = c
		if isleaf(c)
			t.lleaves[label(c)] = c
		end
	end

	# grafting
	graftnode!(r, n; tau)

	return nothing
end
graft!(t, n::TreeNode, r::AbstractString; kwargs...) = graft!(t, n, t[r]; kwargs...)
graft!(t1, t2::Tree, r; kwargs...) = graft!(t1, copy(t2).root, r; kwargs...)


function subtree_prune_regraft!(
	t::Tree, p::AbstractString, g::AbstractString;
	remove_singletons = true, graft_on_leaf = false, create_new_leaf = false,
)
	# Checks
	if !create_new_leaf && length(children(ancestor(t[p]))) == 1
		error("Cannot prune node $p without creating a new leaf (got `create_new_leaf=false`)")
	elseif !graft_on_leaf && isleaf(t[g])
		error("Cannot graft: node $g is a leaf (got `graft_on_leaf=false`")
	end

	# prune
	n, a = prunenode!(t[p])
	if isleaf(a)
		t.lleaves[label(a)] = a
	end

	# graft
	if isleaf(g)
		delete!(t.lleaves, g)
	end
	graft!(t, n, g)

	return nothing
end


"""
	add_internal_singleton!(n::TreeNode, a::TreeNode, τ::Real)

Add internal singleton above `n` and below `a`, at heigh `τ` above `n`.
Return the singleton.
"""
function add_internal_singleton!(n::TreeNode, a::TreeNode, τ::Real, label; v = false)
	# Branch length above n and above the singleton
	nτ, sτ = n.tau >= τ ? (τ, n.tau - τ) : (n.tau, 0.)

	s = TreeNode(; tau = sτ, label)
	prunenode!(n)
	n.tau = nτ
	graftnode!(a, s)
	graftnode!(s, n)
	return s
end
function add_internal_singleton!(n::TreeNode, a::TreeNode, τ::Missing, label; v = false)
	@assert ismissing(n.tau)
	prunenode!(n)
	s = TreeNode(; label)
	graftnode!(a, s)
	graftnode!(s, n)
	return s
end

# function insert_node!(n::TreeNode, label, tau = zero(branch_length(n)))
# 	nτ = branch_length(n)
# 	if ismissing(nτ) != ismissing(tau) || tau > nτ
# 		error("Cannot insert node at height $tau on branch with length $nτ")
# 	end

# 	# Branch length above n and above the singleton
# 	# ancestor(n) -- τ2 --> s -- tau --> n
# 	τ2 = nτ - tau
# 	s = TreeNode(; tau = tau, label)

# end

# """
# 	insert_node!(t::Tree, n::AbstractString; tau = 0.)

# Insert a node on the branch above `n`, at distance `tau` from `n`.
# """
# function insert_node!(t::Tree, n::AbstractString; tau = 0.)

# end




"""
	delete_node!(node::TreeNode; ptau=false)

Delete `node`. If it is an internal node, its children are regrafted on `node.anc`.
Returns the new `node.anc`.
If `ptau`, branch length above `node` is added to the regrafted branch.
Otherwise, the regrafted branch's length is unchanged. Return modified `node.anc`.

Note that the previous node will still be in the dictionary `lnodes` and `lleaves` (if a leaf) and the print function will fail on the tree,
to fully remove from the tree and apply the print function use `delete_node!(t::Tree, label; ptau=false)`
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
		base_tau = node.tau
		for c in reverse(node.child)
			nc = prunenode!(c)[1]
			graftnode!(node.anc, nc, tau = (base_tau*ptau + nc.tau))
		end
		prunenode!(node)
	end
	return out
end

function delete_node!(t::Tree, label; ptau=false)
	delete_node!(t.lnodes[label]; ptau)
	delete!(t.lnodes, label)
	haskey(t.lleaves, label) && delete!(t.lleaves, label)
	remove_internal_singletons!(t; ptau)
	return nothing
end

"""
	delete_null_branches!(tree::Tree; threshold=1e-10)

Delete internal node with branch length smaller than `threshold`. Propagates recursively down the tree. For leaf nodes, set branch length to 0 if smaller than `threshold`.
"""
delete_null_branches!(tree::Tree; threshold=1e-10) = delete_branches!(n -> branch_length(n) < threshold, tree.root)


function delete_branches!(f, n::TreeNode; keep_time=false)
	if !n.isroot && f(n)
		if !n.isleaf
			# if `n` is an internal node, delete it and the branch above.
			child_list, ntau = copy(n.child), branch_length(n)
			delete_node!(n)
			for c in child_list
				if keep_time && !ismissing(ntau) && !ismissing(branch_length(c))
					c.tau += ntau
				end
				delete_branches!(f, c; keep_time)
			end
		else
			# if `n` is a leaf, set its branch length to 0
			n.tau = ismissing(n.tau) ? missing : 0.
		end
	else
		for c in n.child
			delete_branches!(f, c; keep_time)
		end
	end

	return n
end

"""
	delete_branches!(f, tree::Tree)
	delete_branches!(f, n::TreeNode)

Delete branch above node `n` if `f(n)` returns `true` when called on node `n`. When called on a `Tree` propagates recursively down the tree.
Only when called on a `Tree` will nodes be additionally deleted from the `lnodes` and `lleaves` dictionaries.
If `keep_time`, the branch length of the deleted branches will be added to child branches.
"""
function delete_branches!(f, tree::Tree; keep_time=false)
	delete_branches!(f, tree.root)
	remove_internal_singletons!(tree)
	node2tree!(tree, tree.root)
	return nothing
end


"""
	remove_internal_singletons!(tree; ptau=true)

Remove nodes with one child. Root node is left as is.
If `ptau`, the length of branches above removed nodes is added to the branch length above
their children.
"""
function remove_internal_singletons!(tree; ptau=true)
	root = tree.root
	for n in values(tree.lnodes)
		if length(n.child) == 1
			if !n.isroot
				delete_node!(n, ptau=ptau)
				delete!(tree.lnodes, n.label)
			end
		end
	end
	# If root itself is a singleton, delete its child and regraft onto it.
	if length(tree.root.child) == 1 && !tree.root.child[1].isleaf
		n = tree.root.child[1]
		delete_node!(n, ptau=ptau)
		delete!(tree.lnodes, n.label)
	end
	#
	#node2tree!(tree, root)
end


