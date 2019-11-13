export TreeNode, NodeData, Tree, Mutation
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
	mutable struct NodeData

- `q`: number of states for sites 
- sequence
- number of mutations to ancestor
"""
mutable struct NodeData
	q::Int64
	sequence::Array{Char,1}
	mutations::Array{Mutation,1}
	tau::Union{Missing, Float64} # Time to ancestor
	nseg::Int64 # number of segments travelling along upper branch
end
function NodeData(; q = 0., sequence = Array{Char,1}(undef, 0), mutations=Array{Mutation,1}(undef, 0), tau = missing, nseg=1)
	return NodeData(q, sequence, mutations, tau, nseg)
end
function ==(x::NodeData, y::NodeData)
	out = x.q == y.q
	out *= x.sequence == y.sequence
	out *= x.mutations == y.mutations
	out *= x.tau === y.tau  # `===` operates on `missing` returning a bool
	out *= x.nseg === y.nseg
	return out
end


"""
	mutable struct TreeNode

Structural information on the tree, *i.e.* topology and branch length. 
- `anc::Union{Nothing,TreeNode}`: Ancestor
- `child::Array{TreeNode,1}`: List of children
- `tau::Float64`: Time to ancestor
- `isleaf::Bool`
- `isroot::Bool`
"""
mutable struct TreeNode
	anc::Union{Nothing,TreeNode}
	child::Array{TreeNode,1}
	isleaf::Bool
	isroot::Bool
	label::String
	data::NodeData
end
function TreeNode(;
	anc = nothing, 
	child = Array{TreeNode,1}(undef, 0),
	isleaf = true,
	isroot = true,
	label = "",
	data = NodeData())
	return TreeNode(anc, child, isleaf, isroot, label, data)
end
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
	mutable struct NodeInfo

Name and other information about the node. 
"""
mutable struct NodeInfo 
	name::String
end

"""
"""
mutable struct Tree
	root::Union{Nothing, TreeNode}
	nodes::Dict{Int64, TreeNode}
	lnodes::Dict{String, TreeNode}
	leaves::Dict{Int64, TreeNode}
	lleaves::Dict{fieldtype(TreeNode, :label), TreeNode}
end
function Tree(;
	root = TreeNode(),
	nodes = Dict{Int64, TreeNode}(),
	lnodes = Dict{String, TreeNode}(),
	leaves = Dict{Int64, TreeNode}(),
	lleaves = Dict{fieldtype(TreeNode,:label), TreeNode}())
	return Tree(root, nodes, lnodes, leaves, lleaves)
end