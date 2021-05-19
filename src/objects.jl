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



"""
	mutable struct LBIData <: TreeNodeData

Data used to compute the Local Branching Index.
"""
mutable struct LBIData <: TreeNodeData
	tau::Float64
	message_down::Float64
	message_up::Float64
	lbi::Float64
	date
	alive::Bool
end
function LBIData(; tau=0.,
				message_down=0.,
				message_up=0.,
				LBI=0.,
				date=0.,
				alive=true)
	return LBIData(tau, message_down, message_up, LBI, date, alive)
end

default_node_datatype = MiscData

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
function ==(x::TreeNode, y::TreeNode)
	return x.label == y.label
end


"""
	mutable struct Tree{T <: TreeNodeData}
"""
mutable struct Tree{T <: TreeNodeData}
	root::Union{Nothing, TreeNode{T}}
	lnodes::Dict{String, TreeNode{T}}
	lleaves::Dict{fieldtype(TreeNode{T}, :label), TreeNode{T}}
end
function Tree(root::TreeNode{T};
	lnodes = Dict{String, TreeNode{T}}(),
	lleaves = Dict{fieldtype(TreeNode{T},:label), TreeNode{T}}()) where T
	return Tree(root, lnodes,lleaves)
end
Tree() = Tree(TreeNode())


#=
Iterators
=#

