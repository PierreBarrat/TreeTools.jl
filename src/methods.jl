#===================================================#
################## Tree from nodes ##################
#===================================================#

"""
	node2tree(root::TreeNode{T}; label = default_tree_label(), force_new_labels=false)

Create a `Tree` object from `root` with name `label`.
If `force_new_labels`, a random string is added to node labels to make them unique.
"""
function node2tree(
    root::TreeNode{T}; label=default_tree_label(), force_new_labels=false
) where {T}
    if !isroot(root)
        @warn "Creating a tree from non-root node $(root.label)."
    end
    tree = Tree(root, Dict{String,TreeNode{T}}(), Dict{String,TreeNode{T}}(), label)
    node2tree_addnode!(tree, root; force_new_labels)
    return tree
end

function node2tree!(tree::Tree, root::TreeNode; force_new_labels=false)
    tree.root = root
    tree.lnodes = Dict{String,TreeNode}()
    tree.lleaves = Dict{String,TreeNode}()
    return node2tree_addnode!(tree, root; force_new_labels)
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
    @warn "`parse_bootstrap` is not implemented yet, doing nothing and return `missing`."
    return missing
end

"""
	name_nodes!(t::Tree)

Give a label to label-less nodes in `t`.
"""
function name_nodes!(t::Tree)
    return name_nodes!(t.root, collect(keys(t.lnodes)))
end
function name_nodes!(r::TreeNode, labels; i=0)
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
            ii = name_nodes!(c, labels; i=ii)
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
    return l1 == l2
end

"""
	map(f, tree::Tree; kwargs...)
	map(f, node::TreeNode; kwargs...)

Apply `f` to each node in `tree` (or subtree of `node`). Return an array.
Traverse the tree in post order.
Keywords are passed to `postorder_traversal`.
"""
Base.map(f, r::TreeNode; kwargs...) = map(f, postorder_traversal(r; kwargs...))
Base.map(f, tree::Tree; kwargs...) = map(f, root(tree); kwargs...)

"""
	map!(f, t::Tree)
	map!(f, r::TreeNode)

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
	count(f, r::TreeNode)

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

#================================================#
################# Copy / convert #################
#================================================#

function _copy(r::TreeNode, ::Type{T}) where {T<:TreeNodeData}
    !r.isroot && error("Copying non-root node.")
    data = _copy_data(T, r)
    child = if r.isleaf
        Array{TreeNode{T},1}(undef, 0)
    else
        Array{TreeNode{T},1}(undef, length(r.child))
    end
    cr = TreeNode(
        data;
        anc=nothing,
        isleaf=r.isleaf,
        isroot=true,
        label=r.label,
        tau=r.tau,
        child=child,
    )
    for (i, c) in enumerate(r.child)
        _copy!(cr, c, i)
    end
    return cr
end
"""
	_copy!(an::TreeNode{T}, n::TreeNode) where T <: TreeNodeData

Create a copy of `n` with node data type `T` and add it to the children of `an`.
"""
function _copy!(an::TreeNode{T}, n::TreeNode, i) where {T<:TreeNodeData}
    data = _copy_data(T, n)
    child = if n.isleaf
        Array{TreeNode{T},1}(undef, 0)
    else
        Array{TreeNode{T},1}(undef, length(n.child))
    end
    cn = TreeNode(
        data;
        anc=an,
        isleaf=n.isleaf,
        isroot=n.isroot,
        label=n.label,
        tau=n.tau,
        child=child,
    )
    # Adding `cn` to the children of its ancestor `an`
    an.child[i] = cn
    # Copying children of `n`
    for (i, c) in enumerate(n.child)
        _copy!(cn, c, i)
    end

    return nothing
end
_copy_data(::Type{T}, n::TreeNode{T}) where {T<:TreeNodeData} = copy(n.data)
_copy_data(::Type{T}, n::TreeNode) where {T<:TreeNodeData} = T()

"""
	copy(t::Tree; force_new_tree_label = false, label=nothing)

Make a copy of `t`. The copy can be modified without changing `t`. By default `tree.label`
is also copied. If this is not desired `force_new_tree_label=true` will create create a copy
of the tree with a new label. Alternatively a `label` can be set with the `label` argument.
"""
function Base.copy(
    t::Tree{T}; force_new_tree_label=false, label=nothing
) where {T<:TreeNodeData}
    if force_new_tree_label
        node2tree(_copy(t.root, T))
    else
        node2tree(_copy(t.root, T); label=isnothing(label) ? t.label : label)
    end
end

"""
    convert(Tree{T}, t::Tree)
    convert(T, t::Tree)

Create a copy of `t` with data of type `T::TreeNodeData` at nodes (see ?`TreeNodeData`).
"""
Base.convert(::Type{Tree{T}}, t::Tree{T}) where {T<:TreeNodeData} = t
function Base.convert(::Type{Tree{T}}, t::Tree; label=t.label) where {T<:TreeNodeData}
    return node2tree(_copy(t.root, T); label=label)
end
Base.convert(::Type{T}, t::Tree) where {T<:TreeNodeData} = convert(Tree{T}, t)

#========================#
######### Clades #########
#========================#

"""
	node_findroot(node::TreeNode ; maxdepth=1000)

Return root of the tree to which `node` belongs.
"""
function node_findroot(node::TreeNode; maxdepth=1000)
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
    if safe && !mapreduce(isleaf, *, nodelist; init=true)
        return false
    end

    claderoot = lca(nodelist)
    # Check if clade of `claderoot` is the same as `nodelist`
    for c in traversal(claderoot, :postorder; internals=false)
        if !any(==(c), nodelist)
            return false
        end
    end
    return true
end
function isclade(nodelist::AbstractArray{<:AbstractString}, t::Tree)
    return isclade([t.lnodes[n] for n in nodelist])
end

#==================================================================#
####################### LCA, divergence time #######################
#==================================================================#

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
            di -= 1
        else
            jj_node = jj_node.anc
            dj -= 1
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
        if !is_ancestor(ca, node)
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
        if !is_ancestor(ca, t.lnodes[l])
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

Compute branch length distance between `n1` and `n2` by summing the `branch_length` values.
If `topological`, the value `1.` is summed instead, counting the number of branches
separating the two nodes (*Note*: the output is not an `Int`!).
"""
function distance(i_node::TreeNode, j_node::TreeNode; topological=false)
    a_node = lca(i_node, j_node)
    tau = 0.0
    ii_node = i_node
    jj_node = j_node
    while ii_node != a_node
        tau += topological ? 1.0 : ii_node.tau
        ii_node = ii_node.anc
    end
    while jj_node != a_node
        tau += topological ? 1.0 : jj_node.tau
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
	is_ancestor(t::Tree, a::AbstractString, n::AbstractString)
	is_ancestor(a::TreeNode, n::TreeNode)

Check if `a` is an ancestor of `n`, in the sense that `ancestor(ancestor(...(node))) == a`.
"""
function is_ancestor(a::TreeNode, node::TreeNode)
    return if a == node
        true
    else
        isroot(node) ? false : is_ancestor(a, ancestor(node))
    end
end
is_ancestor(t::Tree, a::AbstractString, n::AbstractString) = is_ancestor(t[a], t[n])

"""
	distance_to_deepest_leaf(node::TreeNode; topological=false)

Distance from `node` to the deepest leaf in the clade below `node`.
"""
function distance_to_deepest_leaf(node::TreeNode; topological=false)
    return maximum(postorder_traversal(node; internals=false)) do leaf
        distance(node, leaf; topological)
    end
end
tree_height(tree::Tree; kwargs...) = distance_to_deepest_leaf(root(tree); kwargs...)

"""
    distance_to_shallowest_leaf(node::TreeNode; topological = false)

Distance from `node` to the closest leaf in the clade below `node`.
"""
function distance_to_shallowest_leaf(node::TreeNode; topological=false)
    return minimum(postorder_traversal(node; internals=false)) do leaf
        distance(node, leaf; topological)
    end
end

function distance_to_closest_leaf(tree::Tree, label::AbstractString; topological=false)
    return minimum(l -> distance(tree[label], l; topological), leaves(tree))
end

#=======================================================================================#
############################## Topology: root, binarize... ##############################
#=======================================================================================#

"""
	binarize!(t::Tree; time=0.)

Make `t` binary by adding arbitrary internal nodes with branch length `time`.
"""
function binarize!(t::Tree; mode=:balanced, time=0.0)
    # I would like to implement `mode = :random` too in the future
    z = binarize!(t.root; mode, time)
    node2tree!(t, t.root)
    return z
end
function binarize!(n::TreeNode{T}; mode=:balanced, time=0.0) where {T}
    z = 0
    if length(n.child) > 2
        c_left, c_right = _partition(n.child, mode)
        for part in (c_left, c_right)
            if length(part) > 1
                z += 1
                nc = TreeNode(T(); label=random_label("BINARIZE"))
                for c in part
                    prunenode!(c)
                    graftnode!(nc, c)
                end
                graftnode!(n, nc; time)
            end
        end
    end

    for c in n.child
        z += binarize!(c; mode, time)
    end

    return z
end
function _partition(X, mode)
    # for now mode==:balanced all the time, so it's simple
    L = length(X)
    half = div(L, 2) + mod(L, 2)
    return X[1:half], X[(half + 1):end]
end

#=
root the tree to which `node` belongs at `node`. Base function for rooting.
- If `node.isroot`,
- Else if `newroot == nothing`, root the tree defined by `node` at `node`. Call `root!(node.anc; node)`.
- Else, call `root!(node.anc; node)`, then change the ancestor of `node` to be `newroot`.
=#
function _root!(node::Union{TreeNode,Nothing}; newroot::Union{TreeNode,Nothing}=nothing)
    # Breaking cases
    if node.anc == nothing || node.isroot
        if !(node.anc == nothing && node.isroot)
            @warn "There was a problem with input tree: previous root node has an ancestor."
        elseif newroot != nothing
            i = findfirst(c -> c.label == newroot.label, node.child)
            deleteat!(node.child, i)
            node.anc = newroot
            node.tau = newroot.tau
            node.isroot = false
        end
    else # Recursion
        if newroot == nothing
            # if node.isleaf
            # 	error("Cannot root on a leaf node")
            # end
            node.isroot = true
            _root!(node.anc; newroot=node)
            push!(node.child, node.anc)
            node.anc = nothing
            node.tau = missing
        else
            i = findfirst(c -> c.label == newroot.label, node.child)
            deleteat!(node.child, i)
            _root!(node.anc; newroot=node)
            push!(node.child, node.anc)
            node.anc = newroot
            node.tau = newroot.tau
        end
    end
end
"""
	root!(tree::Tree, node::AbstractString; root_on_leaf, time=0., remove_singletons=true)

Root `tree` at `tree.lnodes[node]`. Equivalent to outgroup rooting.
If `time` is non-zero, root above `node` at height `time`, inserting a new node.

If `remove_singletons`, singleton nodes are removed after re-rooting.
This is useful to remove the old root, which often ends up being a singleton.
"""
function root!(
    tree::Tree, node::AbstractString;
    root_on_leaf=false, time=0.0, remove_singletons=true,
)
    if isleaf(tree[node]) && !ismissing(time) && time == 0
        if root_on_leaf
            # remove `node` from set of leaves
            delete!(tree.lleaves, node)
            tree[node].isleaf = false
        else
            error("Cannot root on a leaf node")
        end
    end

    new_root = if !ismissing(time) && time == 0
        node
    else
        r = try
            insert!(tree, node; time)
        catch
            @error "Error inserting new root at height $time on branch above node $node"
            rethrow()
        end
        label(r)
    end

    _root!(tree.lnodes[new_root])
    tree.root = tree.lnodes[new_root]
    remove_singletons && remove_internal_singletons!(tree) # old root is potentially a singleton
    if label(tree.root) != new_root
        label!(tree, label(tree.root), new_root)
    end
    return nothing
end
"""
	root!(tree; method=:midpoint, topological = false)

Root tree using `method`. Only implemented method is `:midpoint`. 

# Methods

## `:midpoint`

Distance between nodes can be either topological (number of branches) or based on branch
length. Does not create a polytomy at the root: if the midpoint is an already existing
internal node (not the root), creates a new root node at infinitesimal distance below it.

Midpoint rooting will exit without doing anything if
- the distance between the two farthest leaves is `0`. This happens if all branch lengths
   are 0.
- the current root is already the midpoint.

## `:model`

Provide keyword argument `model::Tree`.
Try to root `tree` like `model`. If the two trees only differ by rooting, they will have
the same topology at the end of this. Else, tree will be rerooted but a warning will
be given.
"""
function root!(tree; method=:midpoint, topological=false, model=nothing)
    if method == :midpoint
        root_midpoint!(tree; topological)
    elseif method == :model
        root_like_model!(tree, model)
    else
        throw(ArgumentError("Unknown method $method. Expected `(:midpoint, :model)`"))
    end
    return nothing
end

"""
    root_like_model!(tree, model::Tree)

Try to root `tree` like `model`. If the two trees only differ by rooting, they will have
the same topology at the end of this. Else, tree will be rerooted but a warning will
be given.

*Note*: In the case where `model` has a polytomy at the root and `tree` does have the
corresponding polytomy, the function will try to root `tree` on an internal node, therefore
creating a polytomy and making it similar to `model`.
"""
function root_like_model!(tree, model::Tree)
    @argcheck share_labels(tree, model) """
    `model` and `tree` must share leaves. Leaves of both trees should have the same labels.
    """

    #
    warn_1() = @warn """`tree` and `model` differ by more than rooting, but the rerooting \
    algorithm nonetheless found a sensible root for `tree` and re-rooted.
    Maybe check what you're doing."""
    # Look at the two splits below the root of `model` ...
    M1 = first(children(root(model)))
    M2 = last(children(root(model)))
    S1 = map(label, postorder_traversal(M1; internals=false))
    S2 = map(label, postorder_traversal(M2; internals=false))
    polytomy = length(children(root(model))) > 2

    # ... and to what nodes they correspond in `tree`
    A1 = lca(tree, S1...)
    A2 = lca(tree, S2...)

    R, time = if !isroot(A1) && !isroot(A2)
        # if none of them is the root, then `tree` is already rooted correctly
        if SplitList(model) != SplitList(tree)
            @warn "Tree and model differ too much for rooting. Leaving input tree unchanged."
        end
        return nothing
    elseif isroot(A1) && isroot(A2)
        @warn "Tree and model differ too much for rooting. Leaving input tree unchanged."
        return nothing
    elseif isroot(A1)
        # else, we root on the branch above the one that is not the root
        # branch length is calculated proportionally from model
        if polytomy
            label(ancestor(A2)), 0.
        else
            time = distance(A2, ancestor(A2)) * distance(M2, ancestor(M2)) / distance(M1, M2)
            label(A2), time
        end
    elseif isroot(A2)
        if polytomy
            label(ancestor(A1)), 0.
        else
            time = distance(A1, ancestor(A1)) * distance(M1, ancestor(M1)) / distance(M1, M2)
            label(A1), time
        end
    end
    TreeTools.root!(tree, R; time)

    if SplitList(model) != SplitList(tree)
        warn_1()
    end

    return nothing
end

function root_midpoint!(t::Tree; topological=false)
    exit_warning = "Failed to midpoint root, tree unchanged"
    if length(leaves(t)) == 1
        @warn "Can't midpoint root tree with only one leaf"
        @warn exit_warning
        return nothing
    end

    # Find the good branch
    b_l, b_h, L1, L2, fail = find_midpoint(t; topological)
    fail && (@warn exit_warning; return nothing)
    # The midpoint is between b_l and b_h == b_l.anc
    # L1 and L2 are the farthest apart leaves
    # It's on the side of L1 w.r. to the current root, that is we should be in the situation
    #=
    -- Root --
    |		  |
    b_h		  |
    |		  |
    b_l       |
    |		  |
    L1		  L2
    =#
    # If the midpoint is exactly on b_h and b_h is not the root, we introduce a singleton below to root on.

    d1 = distance(b_l, L1; topological)
    d2 = distance(b_l, L2; topological)
    @debug """
    Midpoint on branch $(label(b_h)) --> $(label(b_l)).
    Farthest apart leaves: $(label(L1)) and $(label(L2)).
    Distances: L1 --> b_l: $(d1) // L2 --> b_h: $(distance(b_h, L2; topological))
    """
    @assert d1 <= d2 """
    Issue with branch lengths.
    If some of the branch lengths are negative, this function should fail.
    """
    if isroot(b_h) && isapprox(abs(d1 - d2), 2 * distance(b_l, b_h; topological))
        # The root is already the midpoint
        @debug """
        Distances to previous root:
        $(L1.label) --> $(distance(t.root, L1; topological)) / $(L2.label) --> $(distance(t.root, L2; topological))
        """
        @debug "Previous root was already midpoint, leaving tree unchanged."
    else
        # Introducing a singleton that will act as the new root.
        τ = if topological
            # root halfway along the branch
            ismissing(b_l) ? missing : b_l.tau / 2
        else
            _τ = (d2 - d1) / 2
            _τ = isapprox(_τ, b_l.tau) ? b_l.tau : _τ # if small numerical error, fix it
        end
        @assert ismissing(τ) || 0 <= τ <= b_l.tau """
        Issue with time on the branch above midpoint.
        Got τ=$τ and expected `missing` or `0 <= τ <= `$(b_l.tau).
        """

        R = insert!(t, b_l; time=τ, name=get_unique_label(t, "MIDPOINT_ROOT"))
        node2tree!(t, t.root)

        @debug "Introducing new root between $(b_l.label) and $(b_h.label)"
        @debug "Distances to R: $(L1.label) --> $(distance(R, L1; topological)) / $(L2.label) --> $(distance(R, L2; topological))"

        # Rooting on R
        root!(t, R.label)
    end

    return nothing
end

function find_midpoint(tree::Tree{T}; topological=false) where {T}
    # Find pair of leaves with largest distance
    max_dist = -Inf
    L1 = ""
    L2 = ""
    depths = _node_depths(tree)
    for (i, n1) in enumerate(leaves(tree)), (j, n2) in enumerate(leaves(tree))
        i <= j && continue

        d = _distance(n1, n2, depths; topological)
        if ismissing(d)
            throw(
                DomainError(d, "Can't midpoint root for tree with missing branch length.")
            )
        end

        if d > max_dist
            max_dist = d
            L1, L2 = (n1.label, n2.label)
        end
    end
    @debug "Farthest leaves: $L1 & $L2 -- distance $max_dist"
    @argcheck L1 != L2 """
    Farthest apart leaves have the same label. Maybe your tree has only one leaf?
    """
    (isempty(L1) || isempty(L2)) && @warn "One of farthest apart leaves has an empty label."

    if max_dist == 0 || ismissing(max_dist)
        @warn "Null or missing branch lengths: cannot midpoint root."
        x = first(nodes(tree))
        return x, x, x, x, true
    end

    # Find leaf farthest away from lca(L1, L2)
    A = lca(tree, L1, L2).label
    d1 = distance(tree, L1, A; topological)
    d2 = distance(tree, L2, A; topological)
    @assert isapprox(d1 + d2, max_dist; rtol=1e-10) # you never know ...
    L_ref = d1 > d2 ? tree[L1] : tree[L2]
    L_other = d1 > d2 ? tree[L2] : tree[L1]

    # Find middle branch: go up from leaf furthest from lca(L1, L2)
    # midpoint is between b_l and b_h
    b_l = nothing
    b_h = L_ref
    d = 0
    it = 0
    while d < max_dist / 2 && !isroot(b_h) && it < 1e5
        d += topological ? 1.0 : branch_length(b_h)
        b_l = isnothing(b_l) ? b_h : b_l.anc
        b_h = b_h.anc
        @assert b_h != A "Issue during midpoint rooting."
        it += 1
    end
    it >= 1e5 && error("Tree too large to midpoint root (>1e5 levels) (or there was a bug)")

    @debug "Midpoint found between $(b_l.label) and $(b_h.label)"
    return b_l, b_h, L_ref, L_other, false
end

"""
	ladderize!(tree::Tree)

Ladderize `tree` by placing nodes with largest clades left in the newick string.
"""
ladderize!(tree::Tree) = ladderize!(tree.root)
function ladderize!(n::TreeNode)
    function _isless(v1::Tuple{Int,String}, v2::Tuple{Int,String})
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
        n.child = n.child[sortperm(rank; lt=_isless)]

        return sum([r[1] for r in rank]), n.label
    end

    return tree
end

#=====================#
######## Other ########
#=====================#

"""
	branches_of_spanning_tree(t::Tree, leaves...)

Return the set of branches of `t` spanning `leaves`.  The output is a `Vector{String}`
containing labels of nodes. The branch above each of these nodes is in the spanning tree.
"""
function branches_in_spanning_tree(t::Tree{T}, leaves::Vararg{String}) where {T}
    R = lca(t, leaves...) # root of the spanning tree
    visited = Dict{String,Bool}()
    for n in leaves
        a = t[n]
        while !haskey(visited, a.label) && a != R
            visited[a.label] = true
            a = t[a.label].anc
        end
    end
    return collect(keys(visited))
end
function branches_in_spanning_tree(t, leaves::Vector{String})
    return branches_in_spanning_tree(t, leaves...)
end
function branches_in_spanning_tree(t, leaves::Vararg{TreeNode})
    return branches_in_spanning_tree(t, Iterators.map(x -> x.label, leaves)...)
end

"""
	resolution_index(t::Tree)

Compute a measure of how resolved `t` is: `R = (I-1) / (L-2)` where `I` is the number of
internal nodes and `L` the number of leaves.
A fully resolved tree has `R=1`. A star tree has `R=0`.
Trees with only one leaf are also considered fully resolved.
"""
function resolution_index(t::Tree)
    if length(leaves(t)) == 1 || length(leaves(t)) == 2
        # if tree only contains 1 or 2 leaves it is resolved
        return 1
    else
        L = length(leaves(t))
        I = length(nodes(t)) - L
        return (I - 1) / (L - 2)
    end
end
resolution_value(t::Tree) = resolution_index(t::Tree)

const tree_distance_types = (:RF,)
"""
	distance(t1::Tree, t2::Tree; type = :RF, normalize = false)

Compute distance between two trees.
See `TreeTools.tree_distance_types` for allowed types.
If `normalize`, the distance is normalized to `[0,1]`.
"""
function distance(t1::Tree, t2::Tree; type=:RF, normalize=false)
    if Symbol(type) == :RF
        return RF_distance(t1, t2; normalize)
    else
        error("Unknown distance type $(type) - see `TreeTools.tree_distance_types`")
    end
end

"""
	RF_distance(t1::Tree, t2::Tree; normalize=false)

Compute the Robinson–Foulds distance between `t1` and `t2`.
RF distance is the sum of the number of splits present in `t1` and not `t2` and in `t2`
and not `t1`.
If `normalize`, the distance is normalized to `[0,1]`.
"""
function RF_distance(t1::Tree, t2::Tree; normalize=false)
    @argcheck share_labels(t1, t2) """
    Cannot compute RF distance for trees that do not share leaves.
    Leaves of both trees should have the same labels.
    """
    s1 = SplitList(t1)
    s2 = SplitList(t2)
    d = length(s1) + length(s2) - 2 * length(TreeTools.intersect(s1, s2))
    if !normalize || (length(s1) + length(s2) < 3)
        # can't normalize if both trees have only the root split
        return d
    else
        return d / (length(s1) + length(s2) - 2)
    end
end

"""
    distance_matrix(tree::Tree)

Pairwise distance between leaves.
The element `D[i,j]` is the distance along branches between leaf `i` and `j`.
Leaves are arranged in *post-order*.
"""
function distance_matrix(tree::Tree)
    # Precompute the depth of each node (i.e. topological distance from root)
    depths = _node_depths(tree)
    distances = zeros(Float64, length(leaves(tree)), length(leaves(tree)))
    for (i, n) in enumerate(traversal(tree, :postorder; internals=false))
        for (j, m) in enumerate(traversal(tree, :postorder; internals=false))
            if i > j
                distances[i,j] = _distance(n, m, depths)
                distances[j,i] = distances[i,j]
            elseif i == j
                distances[i,i] = 0.
            end
        end
    end
    return distances
end

function _distance(x::TreeNode, y::TreeNode, depths::Dict; topological=false)
    Δ = depths[label(x)] - depths[label(y)]
    deep, shallow = Δ > 0 ? (x, y) : (y, x)

    d = 0.
    for _ in 1:abs(Δ)
        d += topological ? 1. : branch_length(deep)
        deep = ancestor(deep)
    end

    while deep != shallow
        if topological
            d += 2.
        else
            d += branch_length(deep) + branch_length(shallow)
        end
        deep = ancestor(deep)
        shallow = ancestor(shallow)
    end

    return d
end
function _node_depths(tree::Tree)
    depths = Dict{String, Int}(label(root(tree)) => 0)
    for c in children(root(tree))
        _node_depths!(c, 0, depths)
    end
    return depths
end
function _node_depths!(node, anc_depth, depths)
    depths[label(node)] = anc_depth + 1
    for c in children(node)
        _node_depths!(c, anc_depth + 1, depths)
    end
    return nothing
end
