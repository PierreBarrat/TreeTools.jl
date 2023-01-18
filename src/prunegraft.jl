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
	prunesubtree!(tree, node)
	prunesubtree!(tree, labels)

Same as `prune!`, but returns the pruned node as a `TreeNode` and its previous ancestor.
See `prune!` for details on `kwargs`.
"""


function prunesubtree!(tree, r::TreeNode; remove_singletons=true, create_leaf = :warn)
	# Checks
	if r.isroot
		error("Trying to prune root in tree $(label(tree))")
	elseif !in(r, tree)
		error("Node $(r.label) is not in tree $(tree.label). Cannot prune.")
	elseif length(children(ancestor(r))) == 1
		if create_leaf == :warn
			@warn "Pruning node $(r.label) will create a new leaf $(ancestor(r).label)"
		elseif !create_leaf
			error("Pruning node $(r.label) will create a new leaf $(ancestor(r).label)")
		end
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
		remove_internal_singletons!(tree, delete_time=false)
	end
	return r, a
end
prunesubtree!(t, r::AbstractString; kwargs...) = prunesubtree!(t, t[r]; kwargs...)

function prunesubtree!(tree, labels::AbstractArray; clade_only=true, kwargs...)
	if clade_only && !isclade(labels, tree)
		error("Can't prune non-clade $labels")
	end
	r = lca(tree, labels)
	return prunesubtree!(tree, r; kwargs...)
end
function prunesubtree!(tree, label1, label2::Vararg{AbstractString}; kwargs...)
	return prunesubtree!(tree, vcat(label1, label2...); kwargs...)
end

"""
	prune!(tree, node; kwargs...)
	prune!(tree, labels::AbstractArray)
	prune!(tree, labels...)

Prune `node` from `tree`.
`node` can be a label or a `TreeNode`.
Return the subtree defined by `node` as a `Tree` object as well as the previous
ancestor of `node`.

If a list of labels is provided, the MRCA of the corresponding nodes is pruned.

## kwargs
- `remove_singletons`: remove singletons (internals with one child) in the tree after pruning. Default `true`.
- `clade_only`: if a list of labels is provided, check that it corresponds to a clade before pruning. Default `true`.
- `create_leaf`: if the ancestor of `r` has only one child (singleton), pruning `r`
   will create a leaf. If `create_leaf == :warn`, this will trigger a warning. If
   `create_leaf = false`, it will trigger an error. If `create_leaf = true`, then this
   is allowed. Default: `:warn`.

## Example
```jldoctest
using TreeTools # hide
tree = parse_newick_string("(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;")
prune!(tree, ["X1", "X2"])
map(label, nodes(tree))

# output

3-element Vector{String}:
 "B"
 "A"
 "R"
```
"""
function prune!(t, r; kwargs...)
	r, a = prunesubtree!(t, r; kwargs...)
	return node2tree(r), a
end
function prune!(t, labels...; kwargs...)
	r, a = prunesubtree!(t, labels...; kwargs...)
	return node2tree(r), a
end

"""
	graft!(tree::Tree, n, r; graft_on_leaf=false)

Graft `n` onto `r`.
`r` can be a label or a `TreeNode`, and should belong to `tree`.
`n` can be a `TreeNode` or a `Tree`.
In the latter case, `n` will be *copied* before being grafted.
None of the nodes of the subtree of `n` should belong to `tree`.

If `r` is a leaf and `graft_on_leaf` is set to `false` (default), will raise an error.
"""
function graft!(
	t::Tree{T}, n::TreeNode{T}, r::TreeNode;
	graft_on_leaf=false, tau = branch_length(n),
) where T
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
function graft!(t::Tree{T}, n::TreeNode{R}, r::TreeNode; kwargs...) where T where R
	error(
		"Cannot graft node of type $(typeof(n)) on tree of type $(typeof(t)).
		Try to change node data type"
	)
end

graft!(t, n::TreeNode, r::AbstractString; kwargs...) = graft!(t, n, t[r]; kwargs...)
graft!(t1, t2::Tree, r; kwargs...) = graft!(t1, copy(t2).root, r; kwargs...)


#= NOT TESTED -- TODO =#
function __subtree_prune_regraft!(
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


# """
# 	add_internal_singleton!(n::TreeNode, a::TreeNode, τ::Real)

# Add internal singleton above `n` and below `a`, at heigh `τ` above `n`.
# Return the singleton.
# """
# function add_internal_singleton!(n::TreeNode, a::TreeNode, τ::Real, label)
# 	# Branch length above n and above the singleton
# 	nτ, sτ = n.tau >= τ ? (τ, n.tau - τ) : (n.tau, 0.)

# 	s = TreeNode(; tau = sτ, label)
# 	prunenode!(n)
# 	n.tau = nτ
# 	graftnode!(a, s)
# 	graftnode!(s, n)
# 	return s
# end
# function add_internal_singleton!(n::TreeNode, a::TreeNode, τ::Missing, label)
# 	@assert ismissing(n.tau)
# 	prunenode!(n)
# 	s = TreeNode(; label)
# 	graftnode!(a, s)
# 	graftnode!(s, n)
# 	return s
# end
"""
	insert_node!(c::TreeNode, a::TreeNode, s::TreeNode, time)

Insert `s` between `a` and `c` at height `t`: `a --> s -- t --> c`.
The relation `branch_length(s) + t == branch_length(c)` should hold.
"""
function insert_node!(c::TreeNode{T}, a::TreeNode{T}, s::TreeNode{T}, t::Missing) where T
	@assert ancestor(c) == a
	@assert ismissing(branch_length(c))
	@assert ismissing(branch_length(a))
	@assert ismissing(branch_length(s))

	prunenode!(c)
	graftnode!(a, s)
	graftnode!(s, c)
	return nothing
end
function insert_node!(c::TreeNode{T}, a::TreeNode{T}, s::TreeNode{T}, t::Number) where T
	@assert ancestor(c) == a
	@assert branch_length(s) == branch_length(c) - t
	@assert branch_length(c) >= t

	prunenode!(c)
	branch_length!(c, t)
	graftnode!(a, s)
	graftnode!(s, c)

	return s
end


"""
	insert_node!(tree, node; name, time)

Insert a singleton named `name` above `node`, at height `time` on the branch.
Return the inserted singleton.
`time` can be a `Number` or `missing`.
"""
function insert!(
	t::Tree{T},
	n::TreeNode;
	name = get_unique_label(t),
	time = zero(branch_length(n)),
) where T

	# Checks
	nτ = branch_length(n)
	if isroot(n)
		error("Cannot insert node above root in tree $(label(t))")
	elseif ismissing(time) != ismissing(nτ) || (!ismissing(time) && time > nτ)
		error("Cannot insert node at height $time on branch with length $nτ")
	elseif in(name, t)
		error("node $name is already in tree $(label(t))")
	end

	#
	sτ = nτ - time
	s = TreeNode(; label=name, tau = sτ, data = T())
	insert_node!(n, ancestor(n), s, time)
	t.lnodes[name] = s

	return s
end
insert!(t::Tree, n::AbstractString; kwargs...) = insert!(t, t[n]; kwargs...)



"""
	delete_node!(node::TreeNode; delete_time = false)

Delete `node`. If it is an internal node, its children are regrafted on `node.anc`.
Returns the new `node.anc`.
If `delete_time`, branch length above `node` is not added to the regrafted branch.
Otherwise, the regrafted branch's length is unchanged. Return modified `node.anc`.

Note that the previous node will still be in the dictionary `lnodes` and `lleaves` (if a leaf) and the print function will fail on the tree,
to fully remove from the tree and apply the print function use `delete_node!(t::Tree, label)`
"""
function delete_node!(node::TreeNode; delete_time = false)
	node.isroot && error("Cannot delete root node")

	ptau = !delete_time
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

"""
	delete!(tree::Tree, label; delete_time = false, remove_internal_singletons = true)

Delete node `label` from `tree`.
Children of `label` are regrafted onto its ancestor.

If `delete_time`, the branch length above deleted node is also deleted,
otherwise it is added to the regrafted branch.
If `remove_internal_singletons`, internal singletons are removed after node is deleted.
"""
function delete!(t::Tree, label; delete_time = false, remove_internal_singletons = true)
	delete_node!(t.lnodes[label]; delete_time)
	delete!(t.lnodes, label)
	haskey(t.lleaves, label) && delete!(t.lleaves, label)
	remove_internal_singletons!(t; delete_time)
	return nothing
end

"""
	delete_null_branches!(tree::Tree; threshold=1e-10)

Delete internal node with branch length smaller than `threshold`. Propagates recursively down the tree. For leaf nodes, set branch length to 0 if smaller than `threshold`.
"""
delete_null_branches!(tree::Tree; threshold=1e-10) = delete_branches!(n -> branch_length(n) < threshold, tree.root)


function delete_branches!(f, n::TreeNode; keep_time=false)
	for c in copy(children(n)) # copy needed since `children(n)` is about to change
		delete_branches!(f, c; keep_time)
	end
	if !isroot(n) && f(n)
		if isleaf(n)
			# if `n` is a leaf, set its branch length to 0
			n.tau = ismissing(n.tau) ? missing : 0.
		else
			delete_node!(n; delete_time = !keep_time)
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
	remove_internal_singletons!(tree; delete_time = false)

Remove nodes with one child. Root node is left as is.
If `delete_time` is set to `false`, the length of branches above removed nodes
is added to the branch length above their children.
"""
function remove_internal_singletons!(tree; delete_time = false)
	root = tree.root
	for n in nodes(tree)
		if length(n.child) == 1
			if !n.isroot
				delete_node!(n; delete_time)
				delete!(tree.lnodes, n.label)
			end
		end
	end
	# If root itself is a singleton, prune its child
	if length(tree.root.child) == 1 && !tree.root.child[1].isleaf
		r = tree.root
		n = r.child[1]

		#
		n.anc = nothing
		n.isroot = true
		tree.root = n

		#
		for i in eachindex(children(r))
			pop!(r.child)
		end
		delete!(tree.lnodes, label(r))
	end

	return nothing
end


