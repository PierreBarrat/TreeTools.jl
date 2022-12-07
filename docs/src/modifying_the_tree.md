# Modifying the tree

On some occasions, it can be useful to modify a phylogenetic tree, *e.g.* removing some clades or branches. 
TreeKnit offers a few methods for this: 
- `prune!` and `prunesubtree!` for pruning a clade. 
- `graft!` for grafting a node onto a tree.
- `insert!` for inserting an internal node on an existing branch of a tree. 
- `delete!` to delete an internal node while keeping the nodes below it. 

## Pruning

There are two functions to prune nodes: `prune!` and `prunesubtree!`. 
They behave exactly the same except for the return value: `prune!` returns the prunde clade as a `Tree` object, while `prunesubtree!` just returns its root as a `TreeNode` object. 
Both also return the previous ancestor of the pruned clade. 
Let's see an example

```@repl prunegraft
using TreeTools # hide
tree = parse_newick_string("(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;")
```

Let's assume that we realized leaves `X1` and `X2` are really a weird outlier in our tree. 
We want to get rid of them. 

```@repl prunegraft
tx, a = prune!(tree, "X1", "X2"); 
tx
tree
```

When called on a list of labels, `prune!` finds the MRCA of the input labels and prunes it from the tree. 
Here, `lca(tree, X1, X2)` is internal node `X`, which is removed from the tree. 
Note that cutting the branch above `X` will leave the internal node `BX` with a single child. 
By default, `prune!` also removes singletons from the input tree.

```@repl prunegraft
map(label, nodes(tree)) # `BX` is not in there
```

This behavior can be changed with the `remove_singletons` keyword argument: 

```@repl prunegraft
let
	tree = parse_newick_string("(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;")
	prune!(tree, "X"; remove_singletons=false)
	map(label, nodes(tree))
end
```

The `prunesubtree!` method does exactly the same as `prune!`, but returns the root of the pruned clade as a `TreeNode`, without converting it to a `Tree`. 
Thus the two calls are equivalent: 

```@repl
using TreeTools # hide
tree = parse_newick_string("(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;") # hide
tx = prune!(tree, "X")[1] # or ... 
tree = parse_newick_string("(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;") # hide
tx = let
	r, a = prunesubtree!(tree, "X")
	node2tree(r)
end
```

## Deleting a node

## Grafting

## Inserting a node

## `TreeNode` level functions

All the methods above take a `Tree` as a first argument. 
As described in [Basic concepts](@ref), the actual information about the tree is contained in `TreeNode` objects, while the `Tree` is basically a wrapper around `TreeNode`s. 
Thus, a method like `prune!` has to do two things: 
1. cut the ancestry relation between two `TreeNode` objects.
2. update the `Tree` object in a consistent way. 

The first part is where the "actual" pruning happens, and is done by the `prunenode!` function, which just takes a single `TreeNode` as input. 
TreeTools has similar "`TreeNode` level" methods (not exported): 
- `prunenode!(n::TreeNode)`: cut the relation between `n` and its ancestor
- `graftnode!(r::TreeNode, n::TreeNode)`: graft `n` onto `r`. 
- `delete_node!(n::TreeNode)`: delete cut the relation between `n` and its ancestor `a`, but re-graft the children of `n` onto `a`. 
- `insert_node!(c, a, s, t)`: insert `s::TreeNode` between `c` and `a`, at height `t` on the branch. 

These methods only act on `TreeNode` objects and do not care about the consistency with the `Tree`. 
In most cases, it's more practical to call the `Tree` level methods. 
However, if speed is important, it might be better to use them. 

## Other useful functions

### Remove singletons

`remove_internal_singletons!`

### Delete insignificant branches