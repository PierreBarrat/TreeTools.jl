module TreeTools

using FASTX
using JSON
using Dates
using Distributions
using Debugger
using BioSequences

##
import Base: ==, cat, copy, getindex, in, intersect, isempty, isequal, iterate, length
import Base: setdiff, show, unique, unique!

##
include("objects.jl")
export Tree, TreeNode, TreeNodeData

include("methods.jl")
export lca, node2tree, node2tree!, node_depth, node_divtime, share_labels

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

