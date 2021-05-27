"""
	abstract type TreeNodeData

Abstract supertype for all data attached to `TreeNode` objects. The *only* requirement is a field `.tau::Union{Missing, <:Real}` containing the time to the ancestor.
"""
abstract type TreeNodeData end


"""
	mutable struct MiscData <: TreeNodeData
"""
mutable struct MiscData <: TreeNodeData
	tau::Union{Missing, Float64}
	dat::Dict{Any,Any}
end
MiscData(;tau=missing, dat=Dict()) = MiscData(tau, dat)
MiscData(tau) = MiscData(tau=tau)


const DEFAULT_NODE_DATATYPE = MiscData

"""
	mutable struct TreeNode{T <: TreeNodeData}

Structural information on the tree, *i.e.* topology and branch length.
- `anc::Union{Nothing,TreeNode}`: Ancestor
- `child::Array{TreeNode,1}`: List of children
- `tau::Float64`: Time to ancestor
- `isleaf::Bool`
- `isroot::Bool`
- `data::T`
"""
mutable struct TreeNode{T <: TreeNodeData}
	anc::Union{Nothing,TreeNode{T}}
	child::Array{TreeNode{T},1}
	isleaf::Bool
	isroot::Bool
	label::String
	data::T
end
function TreeNode(data::T;
	anc = nothing,
	child = Array{TreeNode{T},1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "") where T
	return TreeNode(anc, child, isleaf, isroot, label, data)
end
function TreeNode(; data = default_node_datatype(),
	anc = nothing,
	child = Array{TreeNode{default_node_datatype},1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "")
	return TreeNode(anc, child, isleaf, isroot, label, data)
end


"""
	==(x::TreeNode, y::TreeNode)

Equality of labels between `x` and `y`.
"""
function Base.isequal(x::TreeNode, y::TreeNode)
	return x.label == y.label
end
Base.:(==)(x::TreeNode, y::TreeNode) = isequal(x,y)


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


