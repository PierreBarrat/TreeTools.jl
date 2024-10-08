module TreeTools

using Random

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
export lca, node2tree, node2tree!, node_depth, distance, divtime, share_labels, is_ancestor
export root!

include("iterators.jl")
export POT, POTleaves, nodes, leaves, internals

include("prunegraft.jl")
export insert!, graft!, prune!, prunesubtree!

include("reading.jl")
export parse_newick_string, read_tree

include("writing.jl")
export write_newick, newick

include("misc.jl")
export print_tree, check_tree, print_tree_ascii

include("splits.jl")
export Split, SplitList
export arecompatible, iscompatible

include("simple_shapes.jl")
export star_tree, balanced_binary_tree, ladder_tree



end

