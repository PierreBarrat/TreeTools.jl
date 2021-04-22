module TreeTools


using FastaIO # Needed?
using FASTX
using JSON
using Dates
using Distributions
using Debugger
using BioSequences

##
import Base.show, Base.iterate, Base.length, Base.isequal, Base.in, Base.getindex, Base.setdiff, Base.lastindex, Base.isempty
import Base: ==, unique, unique!, Base.cat, Base.intersect

##
include("objects.jl")
export TreeNode, Tree

include("objectsmethods.jl")
export node2tree, node2tree!, share_labels, node_leavesclade_labels, isclade
export lca, node_depth, node_divtime, node_ancestor_list, isancestor

include("iterators.jl")
export POT, POTleaves

include("mutations.jl")
export Mutation
export compute_mutations!

include("prunegraft.jl")
export prunenode!, prunenode, graftnode!, delete_node!, delete_null_branches!, delete_null_branches
export remove_internal_singletons, prunesubtree!

include("reading.jl")
export read_tree, parse_tree, seq2num

include("writing.jl")
export write_newick, write_fasta, write_newick!, write_branchlength

include("misc.jl")
export print_tree, check_tree, nodeinfo
export show

include("lbi.jl")
export lbi!, set_live_nodes!

include("splits.jl") 
export Split, SplitList
export arecompatible, iscompatible
export getindex, length, iterate, lastindex, unique, unique!

include("sequences.jl")
export fasta2tree!


end

