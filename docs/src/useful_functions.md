```@meta 
DocTestSetup = quote 
	using TreeTools
end
```

# Useful functions

## Copy, convert

To make an independent copy of a tree, simply call `copy`. 
```@repl copy
using TreeTools # hide
tree = parse_newick_string("((A:1,B:1)AB:2,C:3)R;");
tree_copy = copy(tree);
label!(tree_copy, "A", "Alfred") # relabel node A
tree_copy
tree
```

The `convert` function allows one to change the data type attached to nodes: 
```@repl copy
typeof(tree)
data(tree["A"])
tree_with_data = convert(Tree{MiscData}, tree);
typeof(tree_with_data)
data(tree_with_data["A"])["Hello"] = " world!"
```

## MRCA, divergence time

The most recent common ancestor between two nodes or more is found using the function `lca`: 

```@repl copy
lca(tree["A"], tree["B"]) # simplest form
lca(tree, "A", "B") # lca(tree, labels...)
lca(tree, "A", "B", "C") # takes a variable number of labels as input
lca(tree, "A", "AB") # This is not restricted to leaves
```

To compute the distance or divergence time between two tree nodes, use `distance`. 
The `topological` keyword allows computing the number of branches separating two nodes. 
```@repl copy
distance(tree, "A", "C")
distance(tree["A"], tree["C"]; topological=true) 
```

The function `is_ancestor` tells you if one node is found among the ancestors of another. 
This uses equality between `TreeNode`, which simply compares labels, see [Basic concepts](@ref)
```@repl copy
is_ancestor(tree, "A", "C")
is_ancestor(tree, "R", "A")
```

## Tree metrics

### Tree height

```jldoctest metrics
julia> using TreeTools

julia> tree = parse_newick_string("((A:1,B:1)AB:2,(C:3,D:1)CD:1)R;");

julia> height(tree)
4.0

julia> height(tree; topological=true)  # Count edges instead of branch lengths
2.0
```

The `height` function calculates the maximum distance from the root to any leaf. Use `topological=true` to count the number of edges instead of summing branch lengths.

### Tree diameter

`diameter` returns the longest path between any two leaves.

```jldoctest metrics
julia> diameter(tree)
7.0

julia> diameter(tree; topological=true)  # Count edges instead of branch lengths
4.0
```

### Pairwise distance matrix

`distance_matrix` returns the matrix of pairwise distances between all leaves, arranged in post-order.

```jldoctest metrics
julia> D = distance_matrix(tree);

julia> size(D)
(4, 4)

julia> D[1,1]
0.0
```

### Distance between trees

The `distance` function also lets you compute the distance between two trees. 
For now, only the [Robinson-Foulds distance](https://en.wikipedia.org/wiki/Robinson%E2%80%93Foulds_metric) is implemented, but more could come. 

```jldoctest
julia> t1 = parse_newick_string("((A,B,D),C);");

julia> t2 = parse_newick_string("((A,(B,D)),C);");

julia> distance(t1, t2)
1

julia> round(distance(t1, t2; normalize=true), sigdigits=2)
0.33
```