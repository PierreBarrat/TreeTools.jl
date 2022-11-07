# Useful functions

## Copy, convert

To make an independent copy of a tree, simply call `copy`. 
```@repl copy
using TreeTools # hide
tree = parse_newick_string("((A:1,B:1)AB:2,C:3)R;")
tree_copy = copy(tree)
label!(tree_copy, "A", "Alfred") # relabel node A
tree_copy
tree
```

The `convert` function allows one to change the data type attached to nodes: 
```@repl copy
typeof(tree)
data(tree["A"])
tree_with_data = convert(Tree{MiscData}, tree)
typeof(tree_with_data)
data(tree_with_data["A"])["Hello"] = " world!"
data(tree_with_data["A"])
```

## MRCA, divergence time

The most recent common ancestor between two nodes or more is found using the function `lca`: 

```@repl copy
lca(tree["A"], tree["B"]) # simplest form
lca(tree, "A", "B") # lca(tree, labels...)
lca(tree, "A", "B", "C") # takes a variable number of labels as input
```