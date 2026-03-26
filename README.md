[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://pierrebarrat.github.io/TreeTools.jl)
[![CI](https://github.com/PierreBarrat/TreeTools.jl/actions/workflows/CI.yaml/badge.svg)](https://github.com/PierreBarrat/TreeTools.jl/actions/workflows/CI.yaml)

# TreeTools

A Julia package for working with rooted phylogenetic and genealogic trees.

## Installation

```julia
using Pkg
Pkg.add("TreeTools")
```

## Quick start

```julia
using TreeTools

# Parse a tree from a Newick string or file
tree = parse_newick_string("((A:1,B:1)AB:2,C:3)R;")

# Navigate the tree
AB = tree["AB"]
println(branch_length(AB))   # 2.0
println(label(ancestor(AB))) # "R"

# Find the most recent common ancestor of two leaves
println(label(lca(tree, "A", "C"))) # "R"

# Compute distance between two nodes
println(distance(tree, "A", "C"))   # 6.0

# Prune a clade and get it back as a new tree
t_AB, _ = prune!(tree, "A", "B")

# Write to Newick
newick(tree)   # "(C:3.0)R:0.0;"
newick(t_AB)   # "(A:1.0,B:1.0)AB:0.0;"
```

## Features

- **I/O**: read and write Newick files; parse Newick strings
- **Navigation**: access ancestors, children, branch lengths, and labels; compute LCA and pairwise distances
- **Modification**: prune clades, graft subtrees, insert and delete nodes, re-root (midpoint, model-based, or at a specific node)
- **Iteration**: post-order and pre-order traversal, or fast arbitrary-order iteration; `map`, `map!` and `count` over nodes
- **Node data**: attach arbitrary typed data to nodes via a parametric `TreeNodeData` system
- **Tree metrics**: Robinson-Foulds distance, tree diameter, height
- **Splits**: decompose a tree into bipartitions and perform operations on them (not yet documented)
- **Generation**: random trees via birth-death process, Kingman/Yule coalescent, or simple shapes (star, ladder, balanced binary)

## Documentation

Full documentation is available at [pierrebarrat.github.io/TreeTools.jl](https://pierrebarrat.github.io/TreeTools.jl).
