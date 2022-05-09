module TreeTools

using Random

## Iteration
import Base: eltype, iterate, IteratorEltype, IteratorSize, length
## Indexing
import Base: eachindex, firstindex, get!, getindex, lastindex, setindex!

## Others
import Base: ==, cat, convert, copy, count, hash, in, intersect
import Base: isempty, isequal, keys, map!, setdiff, show, size
import Base: union, union!, unique, unique!

##
include("objects.jl")
export Tree, TreeNode, TreeNodeData, MiscData
export isleaf, isroot

include("methods.jl")
export lca, map!, node2tree, node2tree!, node_depth, divtime, share_labels

include("iterators.jl")
export POT, POTleaves, nodes, leaves, internals

include("prunegraft.jl")
export delete_node!, graftnode!, prunenode!, prunenode, prunesubtree!

include("reading.jl")
export parse_tree, parse_newick_string, read_tree

include("writing.jl")
export write_newick, write_fasta

include("misc.jl")
export print_tree, check_tree, print_tree_ascii
export show

include("splits.jl")
export Split, SplitList
export arecompatible, iscompatible
export getindex, length, iterate, lastindex, unique, unique!




end

