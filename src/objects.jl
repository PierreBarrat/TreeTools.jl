export TreeNode, NodeData, Tree


"""
	mutable struct NodeData

- `q`: number of states for sites 
- sequence
- number of mutations to ancestor
"""
mutable struct NodeData
	q::Int64
	sequence::Array{Int64,1}
	ntmut_n::Union{Missing, Int64}
	tau::Union{Missing, Float64} # Time to ancestor
end
function NodeData(; q = 0., sequence = Array{Int64,1}(undef, 0), ntmut_n = missing, tau = missing)
	return NodeData(q, sequence, ntmut_n, tau)
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