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

## Distance between trees

The `distance` function also lets you compute the distance between two trees. 
For now, only the [Robinson-Foulds distance](https://en.wikipedia.org/wiki/Robinson%E2%80%93Foulds_metric) is implemented, but more could come. 

```@repl
using TreeTools # hide
t1 = parse_newick_string("((A,B,D),C);")
t2 = parse_newick_string("((A,(B,D)),C);")
distance(t1, t2)
distance(t1, t2; scale=true)
```