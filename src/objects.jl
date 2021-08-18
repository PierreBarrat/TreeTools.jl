"""
	abstract type TreeNodeData

Abstract supertype for all data attached to `TreeNode` objects.
"""
abstract type TreeNodeData end


"""
	struct MiscData <: TreeNodeData
"""
struct MiscData <: TreeNodeData
	dat::Dict{Any,Any}
end
MiscData(; dat=Dict()) = MiscData(dat)

"""
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
function TreeNode(data::T;
	anc = nothing,
	child = Array{TreeNode{T},1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "",
	tau = missing,
) where T
	return TreeNode(anc, child, isleaf, isroot, label, tau, data)
end
function TreeNode(; data = DEFAULT_NODE_DATATYPE(),
	anc = nothing,
	child = Array{TreeNode{typeof(data)},1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "",
	tau = missing,
)
	return TreeNode(anc, child, isleaf, isroot, label, tau, data)
end
isleaf(n) = n.isleaf
isroot(n) = n.isroot


"""
	==(x::TreeNode, y::TreeNode)

Equality of labels between `x` and `y`.
"""
function Base.isequal(x::TreeNode, y::TreeNode)
	return x.label == y.label
end
Base.:(==)(x::TreeNode, y::TreeNode) = isequal(x,y)
Base.hash(x::TreeNode, h::UInt) = hash(x.label, h)


"""
	mutable struct Tree{T <: TreeNodeData}
"""
mutable struct Tree{T <: TreeNodeData}
	root::Union{Nothing, TreeNode{T}}
	lnodes::Dict{String, TreeNode{T}}
	lleaves::Dict{fieldtype(TreeNode{T}, :label), TreeNode{T}}
end
function Tree(root::TreeNode{T};
		lnodes = Dict{String, TreeNode{T}}(root.label => root),
		lleaves = Dict{fieldtype(TreeNode{T},:label), TreeNode{T}}(root.label => root)
	) where T
	return Tree(root, lnodes, lleaves)
end
Tree() = Tree(TreeNode())


