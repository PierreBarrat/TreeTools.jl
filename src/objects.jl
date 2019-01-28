export TreeNode, NodeData, Tree

import Base: ==

"""
	mutable struct NodeData

- `q`: number of states for sites 
- sequence
- number of mutations to ancestor
"""
mutable struct NodeData
	q::Int64
	sequence::Array{Int64,1}
	n_ntmut::Union{Missing, Int64}
	tau::Union{Missing, Float64} # Time to ancestor
end
function NodeData(; q = 0., sequence = Array{Int64,1}(undef, 0), ntmut_n = missing, tau = missing)
	return NodeData(q, sequence, ntmut_n, tau)
end
function ==(x::NodeData, y::NodeData)
	out = x.q == y.q
	out *= x.sequence == y.sequence
	out *= x.n_ntmut === y.n_ntmut # `===` operates on `missing` returning a bool
	out *= x.tau === y.tau
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

Equality between **subtrees** defined by `x` and `y`. This avoids having to recursively check ancestry. 
"""
function ==(x::TreeNode, y::TreeNode)
	# out = (isempty(x.child) && isempty(y.child)) || (x.child[1] == y.child[1] && x.child[1] == y.child[1]) || (x.child[1] == y.child[2] && x.child[2] == y.child[1])
	if isempty(x.child)
		out = isempty(y.child)
	elseif isempty(y.child)
		out = isempty(x.child)
	else
		if length(x.child) != 2 || length(y.child) != 2
			println("Node $(x.label): $(length(x.child)) children\n Node $(y.label): $(length(y.child)) children")
			error("Tree is not binary")
		end
		out = (x.child[1] == y.child[1] && x.child[1] == y.child[1]) || (x.child[1] == y.child[2] && x.child[2] == y.child[1])
	end
	out *= x.isleaf == y.isleaf
	out *= x.isroot == y.isroot
	out *= x.label == y.label
	out *= x.data == y.data
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
	leaves::Dict{Int64, TreeNode}
end
function Tree(;
	root = TreeNode(),
	nodes = Dict{Int64, TreeNode}(),
	leaves = Dict{Int64, TreeNode}())
	return Tree(root, nodes, leaves)
end