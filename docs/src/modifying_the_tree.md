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

`delete!(tree, label)` removes a single internal node while keeping the subtree below it: the children of the deleted node are re-grafted directly onto its ancestor.
This is different from `prune!`, which removes an entire subtree.

```jldoctest delete
julia> using TreeTools

julia> tree = parse_newick_string("(A:1.,(X1:1.,X2:1.)X:2.)R;");

julia> delete!(tree, "X");

julia> sort(map(label, nodes(tree)))
4-element Vector{String}:
 "A"
 "R"
 "X1"
 "X2"
```

By default, the branch length above the deleted node is absorbed into the children's branches, preserving the total distance from ancestor to leaf:

```jldoctest delete
julia> branch_length(tree["X1"]) # original 1. + X's branch 2. = 3.
3.0
```

Setting `delete_time=true` discards the deleted branch length instead:

```jldoctest delete
julia> tree2 = parse_newick_string("(A:1.,(X1:1.,X2:1.)X:2.)R;");

julia> delete!(tree2, "X"; delete_time=true);

julia> branch_length(tree2["X1"])
1.0
```

## Grafting

`graft!(tree, n, r)` attaches `n` as a new child of `r` in `tree`.
`n` can be a `TreeNode` or a `Tree`, and `r` can be a node or a label.
When `n` is a `Tree`, it is **copied** before being grafted.
The keyword `time` sets the branch length of the grafted subtree.

```jldoctest graft
julia> using TreeTools

julia> tree = parse_newick_string("(A:1.,B:2.)R;");

julia> subtree = parse_newick_string("(C:1.,D:1.)CD;");

julia> graft!(tree, subtree, "R"; time=3.)
Node CD:
Ancestor: R, branch length = 3.0
2 children: ["C", "D"]

julia> sort(map(label, nodes(tree)))
6-element Vector{String}:
 "A"
 "B"
 "C"
 "CD"
 "D"
 "R"

julia> branch_length(tree["CD"])
3.0
```

By default, `graft!` errors when `r` is a leaf. Pass `graft_on_leaf=true` to allow it.

## Inserting a node

`insert!(tree, node; name, time)` inserts a new internal node on the branch above `node`.
The `time` argument controls how the branch is split: it is the length of the **lower** part, from the new node down to `node`.
The function returns the newly inserted node.

```jldoctest insert
julia> using TreeTools

julia> tree = parse_newick_string("(A:3.,(B:1.,C:1.)BC:2.)R;");

julia> n = insert!(tree, "A"; name="N", time=2.);

julia> sort(map(label, nodes(tree)))
6-element Vector{String}:
 "A"
 "B"
 "BC"
 "C"
 "N"
 "R"

julia> branch_length(tree["A"]) # lower part: from N down to A
2.0

julia> branch_length(n) # upper part: from R down to N
1.0
```

## Rooting

### Rooting at a specific node

Root the tree at an existing node or at a specific height above it:

```jldoctest root
julia> using TreeTools

julia> tree = parse_newick_string("(A:1,(B:1,C:1)BC:1)R;");
```

**Root at existing node:**
```jldoctest root
julia> root!(tree, "B"; root_on_leaf=true)  # Root at node B - kwarg necessary to allow rooting on leaf

julia> root(tree)
Node B (root)
Ancestor : `nothing` (root)
2 children: ["C", "A"]
```

**Root at specific height above node:**
```jldoctest root
julia> tree = parse_newick_string("(A:3,(B:1,C:1)BC:2)R;");

julia> root!(tree, "A"; time=1.0)  # Create new root 1.0 of time above A

julia> branch_length(tree["A"])
1.0
```

Options:
- `root_on_leaf=true`: Allow rooting on leaf nodes
- `remove_singletons=false`: Keep singleton nodes (default removes them)

### Method-based rooting

**Midpoint rooting:**
```jldoctest root
julia> tree = parse_newick_string("(A:1,(B:1,(C:1,D:1)CD:1)BCD:1)R;");

julia> root!(tree; method=:midpoint)  # Root at midpoint between farthest leaves

julia> d = distance(tree, "A", "D") # this has not changed from previous tree
4.0

julia> isapprox(depth(tree["A"]), d/2, rtol=1e-10)
true
```

Keyword argument `topological=true` allows to use branch count instead of branch lengths for the position of the midpoint.

**Model-based rooting:**
The idea is to root a given tree by taking another as a model. The trees need to be topologically compatible, but branch length does not matter. 
```@repl 
using TreeTools

tree = parse_newick_string("(A:1,(B:1,C:1)BC:1)R;")

model = parse_newick_string("((A:1,B:1)AB:1,C:1)R;")

root!(tree; method=:model, model=model) # try to root like model 

tree
```

Useful when you need multiple trees to have identical rooting.

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