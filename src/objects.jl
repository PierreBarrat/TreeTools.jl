export TreeNode, NodeData, Tree
export have_equal_children

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
	if x.label != y.label
		return false
	end
	out = true
	out *= x.isleaf == y.isleaf
	out *= x.isroot == y.isroot
	out *= x.data == y.data
	# out *= have_equal_children(x,y)
	return out
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
	leaves::Dict{Int64, TreeNode}
	lleaves::Dict{fieldtype(TreeNode, :label), TreeNode}
end
function Tree(;
	root = TreeNode(),
	nodes = Dict{Int64, TreeNode}(),
	leaves = Dict{Int64, TreeNode}(),
	lleaves = Dict{fieldtype(TreeNode,:label), TreeNode}())
	return Tree(root, nodes, leaves, lleaves)
end