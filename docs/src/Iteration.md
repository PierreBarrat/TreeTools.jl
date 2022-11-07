# Iteration: going through a tree

TreeTools offers two different ways to iterate through nodes: post-order traversal, and arbitrary iteration. 

## Post-order traversal

The exact definition can be found [here](https://en.wikipedia.org/wiki/Tree_traversal#Post-order,_LRN). 
This order of iteration guarantees that: 
1. children nodes are always visited before parent nodes
2. the order in which children of a node are visited is the same as that given in `children(node)`. 

```@repl iteration_1
using TreeTools # hide
tree = parse_newick_string("((A:1,B:1)AB:2,C:3)R;")
for n in POT(tree)
	println(n)
end
```

If you want to access only leaves, you can always filter the results: 
```@repl iteration_1
for n in Iterators.filter(isleaf, POT(tree))
	println("$(label(n)) is a leaf")
end
```

Note that `POT` can also be called on `TreeNode` objects. 
In this case, it will only iterate through the clade below the input node, including its root: 
```@repl iteration_1
let
	node = tree["AB"]
	X = map(label, POT(node))
	println("The nodes in the clade defined by $(label(node)) are $(X).")
end
```

### `map`, `count`, etc...

In some cases, one wants to do something like count the number of nodes that have a given property, or apply some function `f` to each node and collect the result. 
To facilitate this, TreeTools extends the Base functions `map`, `map!` and `count` to `Tree` and `TreeNode` objects. 
Using these functions will traverse the tree in post-order. 
If called on a `TreeNode` object, they will only iterate through the clade defined by this node. 

```@repl iteration_1
map(branch_length, tree) # Branch length of all nodes, in POT 
map!(tree) do node # Double the length of all branches - map! returns `nothing`
	x = branch_length(node)
	if !ismissing(x) branch_length!(node, 2*x) end
end
map(branch_length, tree) # Doubled branch length, except for root (`missing`)
count(n -> label(n)[1] == 'A', tree) # count the nodes with a label starting with 'A'
```

Note that there is a difference between the TreeTools extension of `map!` with respect Base: in TreeTools, `map!` returns nothing instead of an array. 

## Arbitrary order

As explained in [Basic concepts](@ref), a `Tree` object is mainly a dictionary mapping labels to `TreeNode` objects.
We can thus iterate through nodes in the tree using this dictionary. 
For this, TreeTools provides the `nodes`, `leaves` and `internals` methods. 
Note that this will traverse the tree in an arbitrary order.  

```@repl iteration_1
for n in leaves(tree)
	println("$(label(n)) is a leaf")
end
for n in internals(tree)
	println("$(label(n)) is an internal node")
end
map(label, nodes(tree)) == union(
	map(label, leaves(tree)), 
	map(label, internals(tree))
)
```

## A note on efficiency

Iterating through nodes using `nodes` will be faster than using `POT`. This is mainly because of my inability to write an efficient iterator: currently, `POT` will allocate a number of times that is proportional to the size of the tree. Below is a simple example where we define functions that count the number of nodes in a tree:

```@example iteration_2
using TreeTools # hide
count_nodes_pot(tree) = sum(x -> 1, POT(tree)) # Traversing the tree in post-order while summing 1
count_nodes_arbitrary(tree) = sum(x -> 1, nodes(tree)) # Arbitrary order
nothing # hide
```

These two functions obviously give the same result, but not with the same run time. Here, we try it on the `example/tree_10.nwk` file: 

```@repl iteration_2
tree = read_tree("../../examples/tree_10.nwk")
using BenchmarkTools
@btime count_nodes_pot(tree)
@btime count_nodes_arbitrary(tree)
```

If a fast post-order is needed, the only solution in the current state of TreeTools is to "manually" program it. 
The code below defines a more efficient to count nodes, traversing the tree in post-order. 

```@example iteration_2
function count_nodes_eff_pot(n::TreeNode, cnt = 0) # this counts the number of nodes below `n`
	for c in children(n)
		cnt += count_nodes_eff_pot(c, 0) # 
	end
	return cnt + 1
end

function count_nodes_eff_pot(tree::Tree)
	return count_nodes_eff_pot(tree.root, 0)
end
```

This will run faster than `count_nodes_pot`, and does not allocate. 
For counting nodes, this is really overkill, and one could just call `length(nodes(tree))`. 
In particular, traversing the tree in a precise order does not matter at all. 
But for more complex use case, writing short recursive code as above does not add a lot of complexity. 

```@repl iteration_2
@btime count_nodes_eff_pot(tree)
```