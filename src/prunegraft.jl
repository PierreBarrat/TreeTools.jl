"""
	prunenode!(node::TreeNode)

Prune node `node` by detaching it from its ancestor. Return pruned `node` and its previous
  ancestor.
"""
function prunenode!(node::TreeNode)
	if node.isroot
		@warn "Trying to prune root: no op."
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
			deleteat!(anc.child,i)
			break
		end
	end
	node_.anc = nothing
	node_.isroot = true
	return node_, r
end


"""
	prunesubtree!(tree, r::TreeNode)
	prunesubtree!(tree, labellist)

Prune and subtree corresponding to the MRCA of labels in `labellist`.
  Return the root of the subtree as well as its previous direct ancestor.
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

"""
	remove_internal_singletons!(tree; ptau=true)

Remove nodes with one child. Root node is left as is.
If `ptau`, the length of branches above removed nodes is added to the branch length above their children.
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


"""
	graftnode!(r::TreeNode, n::TreeNode ; tau=n.tau)

Graft `n` on `r`.
"""
function graftnode!(r::TreeNode, n::TreeNode ; tau=n.tau)
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
	delete_node!(node::TreeNode; ptau=false)

Delete `node`. If it is an internal node, its children are regrafted on `node.anc`. Returns the new `node.anc`.  
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
delete_null_branches!(tree::Tree; threshold=1e-10) = delete_branches!(n -> branch_length(n) < threshold)


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

