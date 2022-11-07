# Reading and writing

For now, TreeTools only handles the [Newick format](https://en.wikipedia.org/wiki/Newick_format). 
Functions are quite basic at this stage. 

## Reading

If you have a variable containing a Newick string, simply call `parse_newick_string` to return a tree. 
To read from a file, use `read_tree`. 
Here is an example with the `example/tree_10.nwk` file: 

```@example
using TreeTools # hide
tree = read_tree("../../examples/tree_10.nwk")
```

The documentation reproduced below gives more information: 

```@docs
TreeTools.read_tree
```

`read_tree` will also read files containing several Newick strings, provided they are on separate lines. 
It then returns an array of `Tree` objects. 


If internal nodes of a Newick string do not have names, TreeTools will by default give them names of the form `NODE_i` with `i::Int`. 
This happens during parsing of the Newick string, in the `parse_newick!` function. 
This label is technically not guaranteed to be unique: the Newick string may also contain nodes with the same name. 
In some cases, it is thus necessary to create a unique identifier for a node. 
This is done by creating a random string obtained with the call `Random.randstring(8)`, and happens at a later stage, when calling the `node2tree` function (see the section about [Tree](@ref)). 
This happens when: 
- the node label is found to be a bootstrap value (see `?TreeTools.isbootstrap`). 
- the option `force_new_labels` is used when calling `read_tree`. This is useful if some internal nodes of the Newick string have redundant names. 
- for some reason, the node does not yet have a label. 

There are about $2\cdot 10^{14}$ strings of length 8 (alphabetic + numeric characters), so this should be fine for most problems. A quick calculation shows that for a tree of 1000 leaves, the probability of obtaining two equal identifiers for different nodes is $\sim 2 \cdot 10^{-9}$, which is probably acceptable for most applications. If you think it's not enough, I can add a handle to let user create longer strings, or solve this in a more elegant way. 



## Writing

To write `t::Tree` to a Newick file, simply call `write(filename, t)`. 
If you want to append to a file, call `write(filename, t, "a")`. 
Note that `write(filename, t)` adds a newline `'\n'` character at the end of the Newick string. 
This is done in case other trees have to be added to the file. 