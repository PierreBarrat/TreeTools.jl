"""
	abstract type TreeNodeData

Abstract supertype for data attached to the `dat` field of `TreeNode` objects.
Implemented concrete types are
- `EmptyData`: empty struct. Use if you do not have to attach data to nodes.
- `MiscData`: contains a dictionary for attaching extra data to nodes. Also behaves like
   a `Dict` for indexing/iterating, *e.g.* `x.dat[key] == x[key]`.
"""
abstract type TreeNodeData end

"""
	struct MiscData <: TreeNodeData
		dat::Dict{Any,Any}
	end
"""
struct MiscData <: TreeNodeData
	dat::Dict{Any,Any}
end
MiscData(; dat=Dict()) = MiscData(dat)

Base.iterate(d::MiscData) = iterate(d.dat)
Base.iterate(d::MiscData, state) = iterate(d.dat, state)
Base.eltype(::Type{MiscData}) = eltype(Dict{Any,Any})
Base.length(d::MiscData) = length(d.dat)

Base.getindex(d::MiscData, i) = getindex(d.dat, i)
Base.setindex!(d::MiscData, k, v) = setindex!(d.dat, k, v)
Base.firstindex(d::MiscData, i) = firstindex(d.dat, i)
Base.lastindex(d::MiscData, i) = lastindex(d.dat, i)
Base.get!(d::MiscData, k, v) = get!(d.dat, k, v)

Base.haskey(d::MiscData, k) = haskey(d.dat, k)

"""
	struct EmptyData <: TreeNodeData
"""
struct EmptyData <: TreeNodeData
end

const DEFAULT_NODE_DATATYPE = EmptyData

"""
	mutable struct TreeNode{T <: TreeNodeData}

Structural information on the tree, *i.e.* topology and branch length.
- `anc::Union{Nothing,TreeNode}`: Ancestor
- `child::Array{TreeNode,1}`: List of children
- `isleaf::Bool`
- `isroot::Bool`
- `tau::Union{Missing, Float64}`
- `data::T`
"""
mutable struct TreeNode{T <: TreeNodeData}
	anc::Union{Nothing,TreeNode{T}}
	child::Array{TreeNode{T},1}
	isleaf::Bool
	isroot::Bool
	label::String
	tau::Union{Missing, Float64}
	data::T
end
function TreeNode(
	data::T;
	anc = nothing,
	child = Array{TreeNode{T},1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "",
	tau = missing,
) where T
	return TreeNode(anc, child, isleaf, isroot, label, tau, data)
end
function TreeNode(;
	data = DEFAULT_NODE_DATATYPE(),
	anc = nothing,
	child = Array{TreeNode{typeof(data)},1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "",
	tau = missing,
)
	return TreeNode(anc, child, isleaf, isroot, label, tau, data)
end

"""
	==(x::TreeNode, y::TreeNode)

Equality of labels between `x` and `y`.
"""
function Base.isequal(x::TreeNode, y::TreeNode)
	return x.label == y.label
end
Base.:(==)(x::TreeNode, y::TreeNode) = isequal(x,y)
Base.hash(x::TreeNode, h::UInt) = hash(x.label, h)

children(n::TreeNode) = n.child
ancestor(n::TreeNode) = n.anc
branch_length(n::TreeNode) = n.tau
branch_length!(n::TreeNode, τ::Union{Missing, Real}) = (n.tau = τ)
label(n::TreeNode) = n.label
isleaf(n) = n.isleaf
isroot(n) = n.isroot

"""
	mutable struct Tree{T <: TreeNodeData}
"""
mutable struct Tree{T <: TreeNodeData}
	root::Union{Nothing, TreeNode{T}}
	lnodes::Dict{String, TreeNode{T}}
	lleaves::Dict{fieldtype(TreeNode{T}, :label), TreeNode{T}}
	label::String
end
function Tree(
	root::TreeNode{T};
	lnodes = Dict{String, TreeNode{T}}(root.label => root),
	lleaves = Dict{fieldtype(TreeNode{T}, :label), TreeNode{T}}(root.label => root),
	label = default_tree_label()
) where T
	return Tree(root, lnodes, lleaves, label)
end
Tree() = Tree(TreeNode())

function Base.in(n::AbstractString, t::Tree; exclude_internals=false)
	exclude_internals ? haskey(t.lleaves, n) : haskey(t.lnodes, n)
end
Base.in(n::TreeNode, t::Tree; exclude_internals=false) = in(n.label, t; exclude_internals)

Base.getindex(t::Tree, label) = getindex(t.lnodes, label)

label(t::Tree) = t.label
label!(t::Tree, label::AbstractString) = (t.label = string(label))
