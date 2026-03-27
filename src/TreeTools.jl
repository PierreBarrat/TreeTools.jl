module TreeTools

using ArgCheck
using Random
using ResumableFunctions

## Iteration
import Base: eltype, iterate, IteratorEltype, IteratorSize, length
## Indexing
import Base: eachindex, firstindex, get!, getindex, lastindex, setindex!

## Others
import Base: ==, cat, convert, copy, count, delete!, hash, in, insert!, intersect
import Base: isempty, isequal, keys, map, map!, setdiff, show, size
import Base: union, union!, unique, unique!, write

##
include("objects.jl")
export Tree, TreeNode, TreeNodeData, MiscData
export isleaf, isroot, isinternal
export ancestor, children, branch_length, branch_length!, label, label!
export data, data!, root

include("methods.jl")
export lca, node2tree, node2tree!, depth, distance, divtime, share_labels, is_ancestor, ancestors
export root!, height
export diameter, distance_matrix
export binarize!, ladderize!

include("iterators.jl")
export nodes, leaves, internals
export traversal, postorder_traversal, preorder_traversal

# include("better_iterators.jl")

include("prunegraft.jl")
export insert!, graft!, prune!, prunesubtree!
export delete_null_branches!, delete_branches!

include("reading.jl")
export parse_newick_string, read_tree

include("writing.jl")
export newick
public write_newick

include("misc.jl")
export print_tree, check_tree, print_tree_ascii

include("splits.jl")
export Split, SplitList
export arecompatible, iscompatible

include("Generate/Generate.jl")
public Generate

# Deprecations
@deprecate tree_height(tree::Tree; kwargs...) height(tree::Tree; kwargs...)
@deprecate node_depth depth
@deprecate node_findroot root
@deprecate node_ancestor_list ancestors
@deprecate POT(tree) traversal(tree, :postorder) false
@deprecate POTleaves(tree) traversal(tree, :postorder; internals=false) false
@deprecate write_newick(tree::Tree; kwargs...) newick(tree; kwargs...) false
@deprecate write_newick(node::TreeNode) newick(node) false

end
