```@meta
DocTestSetup = quote
	using TreeTools
end
```

# Iteration: going through a tree

TreeTools offers two different ways to iterate through nodes: post/pre-order traversals, and arbitrary iteration. 

## Traversals

The call `traversal(tree, style)` returns an iterator over the nodes of `tree`. 
`style` can take two values: `:preorder` or `:postorder`. 
The exact definition of the two traversals can be found [here](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search). 
In short, the traversal guarantees that: 
1. for `:postorder` (resp. `:preorder`), children nodes are always visited before (resp. after) parent nodes; 
2. the order in which children of a node are visited is the same as that given in `children(node)`;
3. the order is "depth-first": iteration over a subtree finishes before the next subtree starts. 
```jldoctest traversal
julia> tree = parse_newick_string("((A:1,B:1)AB:2,C:3)R;");

julia> for node in traversal(tree, :postorder)
	# do something with node
end

julia> map(label, traversal(tree, :postorder))
5-element Vector{String}:
 "A"
 "B"
 "AB"
 "C"
 "R"

julia> map(label, traversal(tree, :preorder))
5-element Vector{String}:
 "R"
 "AB"
 "A"
 "B"
 "C"
```

Note that `traversal` can also be called on `TreeNode` objects:
```jldoctest traversal
julia> map(label, traversal(tree, :preorder)) == map(label, traversal(root(tree), :preorder))
true
```

The `traversal` function accepts boolean keyword arguments `leaves`, `root` and `internals`.
If any of those is set to false, the corresponding nodes are skipped: 
```jldoctest traversal
julia> map(label, traversal(tree, :postorder, leaves=false))
2-element Vector{String}:
 "AB"
 "R"

julia> map(label, traversal(tree, :preorder, internals=false))
3-element Vector{String}:
 "A"
 "B"
 "C"
```

One can also skip nodes by passing a function `f` as the first argument. 
The traversal will only return nodes `n` such that `f(n)` is true: 
```jldoctest traversal
julia> map(label, traversal(n -> label(n)[1] == 'A', tree, :postorder))
2-element Vector{String}:
 "A"
 "AB"
```

### `map`, `count`, etc...

In some cases, one wants to do something like count the number of nodes that have a given property, or apply some function `f` to each node and collect the result. 
To facilitate this, TreeTools extends the Base functions `map`, `map!` and `count` to `Tree` and `TreeNode` objects. 
Using these functions will traverse the tree in post-order. 
If called on a `TreeNode` object, they will only iterate through the clade defined by this node. 

```@repl iteration_1
using TreeTools # hide
tree = parse_newick_string("((A:1,B:1)AB:2,C:3)R;"); # hide
map(branch_length, tree) # Branch length of all nodes, in postorder
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
This will traverse the tree in an arbitrary order but is faster than `traversal`.

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

## A note on speed

Iterating through `tree` using `nodes(tree)` will be faster than using `traversal(tree, ...)`. This is mainly because of my inability to write an efficient iterator (any help appreciated).  Below is a simple example where we define functions that count the number of nodes in a tree:

```@example iteration_2
using TreeTools # hide
count_nodes_traversal(tree) = sum(x -> 1, traversal(tree, :postorder)) # Traversing the tree in post-order while summing 1
count_nodes_arbitrary(tree) = sum(x -> 1, nodes(tree)) # Arbitrary order
nothing # hide
```

These two functions obviously give the same result, but not with the same run time. Here, we try it on the `example/tree_10.nwk` file: 

```@repl iteration_2
tree = read_tree("../../examples/tree_10.nwk")
using BenchmarkTools
@btime count_nodes_traversal(tree)
@btime count_nodes_arbitrary(tree)
```

Benchmarks show that this time difference tends to reduce when trees get larger (hundreds of leaves). 
In any case, if a fast post/pre-order is needed, the only solution in the current state of TreeTools is to "manually" program it using a recursive function.  
The code below defines a more efficient to count nodes, traversing the tree in post-order. 

```@example iteration_2
function count_nodes_recursive(n::TreeNode) # this counts the number of nodes below `n`
	cnt = 0
	for c in children(n)
		cnt += count_nodes_recursive(c) # 
	end
	return cnt + 1
end

count_nodes_recursive(tree::Tree) = count_nodes_recursive(tree.root)
nothing # hide
```

This will run faster than `count_nodes_traversal`, and does not allocate. 
For counting nodes, this is really overkill, and one could just call `length(nodes(tree))`. 
In particular, traversing the tree in a precise order does not matter at all. 
But for more complex use case, writing short recursive code as above does not add a lot of complexity. 

```@repl iteration_2
@btime count_nodes_recursive(tree)
```