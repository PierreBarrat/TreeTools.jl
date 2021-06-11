module TreeTools

using FASTX

##
import Base: ==, cat, convert, copy, count, eachindex, eltype, getindex, in, intersect
import Base: isempty, isequal, iterate, length, map!, setdiff, show, unique, unique!

##
include("objects.jl")
export Tree, TreeNode, TreeNodeData

include("methods.jl")
export lca, map!, node2tree, node2tree!, node_depth, node_divtime, share_labels

include("iterators.jl")
export POT, POTleaves, nodes, leaves, internals

include("mutations.jl")
export Mutation
export compute_mutations!

include("prunegraft.jl")
export delete_node!, graftnode!, prunenode!, prunenode, prunesubtree!

include("reading.jl")
export parse_tree, parse_newick, read_tree

include("writing.jl")
export write_newick, write_fasta

include("misc.jl")
export print_tree, check_tree
export show

include("splits.jl")
export Split, SplitList
export arecompatible, iscompatible
export getindex, length, iterate, lastindex, unique, unique!

include("sequences.jl")
export fasta2tree!


end

