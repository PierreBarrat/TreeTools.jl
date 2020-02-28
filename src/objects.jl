export TreeNode, Tree, Mutation
export EvoData, LBIData, TreeNodeData
export have_equal_children

import Base: ==


mutable struct Mutation
	i::Int64
	old
	new
end
function Mutation(x::Tuple{Int64,Any,Any})
	return Mutation(x[1],x[2],x[3])
end
function ==(x::Mutation, y::Mutation)
	mapreduce(f->getfield(x,f)==getfield(y,f), *, fieldnames(Mutation), init=true)
end

"""
	abstract type TreeNodeData

Abstract supertype for all data attached to `TreeNode` objects. The *only* requirement is a field `.tau::Union{Missing, <:Real}` containing the time to the ancestor. 
"""
abstract type TreeNodeData end


"""
	mutable struct EvoData <: TreeNodeData

Notable fields
- `q`: number of states for sites 
- `sequence::Array{Char,1}`
- `mutations::Array{Mutation,1}
"""
mutable struct EvoData <: TreeNodeData
	q::Int64
	sequence::Array{Char,1}
	mutations::Array{Mutation,1}
	tau::Union{Missing, Float64} # Time to ancestor
	nseg::Int64 # number of segments travelling along upper branch
end
function EvoData(; q = 0., sequence = Array{Char,1}(undef, 0), mutations=Array{Mutation,1}(undef, 0), tau = missing, nseg=1)
	return EvoData(q, sequence, mutations, tau, nseg)
end
function ==(x::EvoData, y::EvoData)
	out = x.q == y.q
	out *= x.sequence == y.sequence
	out *= x.mutations == y.mutations
	out *= x.tau === y.tau  # `===` operates on `missing` returning a bool
	out *= x.nseg === y.nseg
	return out
end

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
TreeNode() = TreeNode(EvoData())

"""
	==(x::TreeNode, y::TreeNode)

Equality of labels between `x` and `y`. Checking for other properties of nodes turns out to be quite complicated. 
"""
function ==(x::TreeNode, y::TreeNode)
	return x.label == y.label
end

"""
	have_equal_children(x::TreeNode, y::TreeNode)

Check whether `x` and `y` have the same children, independent on order. `==` is used to compare children.
"""
function have_equal_children(x::TreeNode, y::TreeNode)
	out = true
	# Is x.child included in y.child?
	for cx in x.child
		flag = false
		for cy in y.child
			if cx == cy
				flag = true
				break
			end
		end
		out *= flag
		if !out
			return false
		end
	end
	# And the other way around
	for cy in x.child
		flag = false
		for cx in y.child
			if cx == cy
				flag = true
				break
			end
		end
		out *= flag
		if !out
			return false
		end
	end
	return out
end

"""
	mutable struct Tree{T <: TreeNodeData}
"""
mutable struct Tree{T <: TreeNodeData}
	root::Union{Nothing, TreeNode{T}}
	nodes::Dict{Int64, TreeNode{T}}
	lnodes::Dict{String, TreeNode{T}}
	leaves::Dict{Int64, TreeNode{T}}
	lleaves::Dict{fieldtype(TreeNode{T}, :label), TreeNode{T}}
end
function Tree(root::TreeNode{T};
	nodes = Dict{Int64, TreeNode{T}}(),
	lnodes = Dict{String, TreeNode{T}}(),
	leaves = Dict{Int64, TreeNode{T}}(),
	lleaves = Dict{fieldtype(TreeNode{T},:label), TreeNode{T}}()) where T
	return Tree(root, nodes, lnodes, leaves, lleaves)
end
Tree() = Tree(TreeNode())
