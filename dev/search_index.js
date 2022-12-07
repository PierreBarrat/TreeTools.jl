var documenterSearchIndex = {"docs":
[{"location":"Iteration/#Iteration:-going-through-a-tree","page":"Iteration","title":"Iteration: going through a tree","text":"","category":"section"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"TreeTools offers two different ways to iterate through nodes: post-order traversal, and arbitrary iteration. ","category":"page"},{"location":"Iteration/#Post-order-traversal","page":"Iteration","title":"Post-order traversal","text":"","category":"section"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"The exact definition can be found here.  This order of iteration guarantees that: ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"children nodes are always visited before parent nodes\nthe order in which children of a node are visited is the same as that given in children(node). ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"using TreeTools # hide\ntree = parse_newick_string(\"((A:1,B:1)AB:2,C:3)R;\")\nfor n in POT(tree)\n\tprintln(n)\nend","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"If you want to access only leaves, you can use POTleaves, or simply filter the results: ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"[label(n) for n in POTleaves(tree[\"AB\"])]\nfor n in Iterators.filter(isleaf, POT(tree))\n\tprintln(\"$(label(n)) is a leaf\")\nend","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"Note that POT can also be called on TreeNode objects.  In this case, it will only iterate through the clade below the input node, including its root: ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"let\n\tnode = tree[\"AB\"]\n\tX = map(label, POT(node))\n\tprintln(\"The nodes in the clade defined by $(label(node)) are $(X).\")\nend","category":"page"},{"location":"Iteration/#map,-count,-etc...","page":"Iteration","title":"map, count, etc...","text":"","category":"section"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"In some cases, one wants to do something like count the number of nodes that have a given property, or apply some function f to each node and collect the result.  To facilitate this, TreeTools extends the Base functions map, map! and count to Tree and TreeNode objects.  Using these functions will traverse the tree in post-order.  If called on a TreeNode object, they will only iterate through the clade defined by this node. ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"map(branch_length, tree) # Branch length of all nodes, in POT \nmap!(tree) do node # Double the length of all branches - map! returns `nothing`\n\tx = branch_length(node)\n\tif !ismissing(x) branch_length!(node, 2*x) end\nend\nmap(branch_length, tree) # Doubled branch length, except for root (`missing`)\ncount(n -> label(n)[1] == 'A', tree) # count the nodes with a label starting with 'A'","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"Note that there is a difference between the TreeTools extension of map! with respect Base: in TreeTools, map! returns nothing instead of an array. ","category":"page"},{"location":"Iteration/#Arbitrary-order","page":"Iteration","title":"Arbitrary order","text":"","category":"section"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"As explained in Basic concepts, a Tree object is mainly a dictionary mapping labels to TreeNode objects. We can thus iterate through nodes in the tree using this dictionary.  For this, TreeTools provides the nodes, leaves and internals methods.  Note that this will traverse the tree in an arbitrary order.  ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"for n in leaves(tree)\n\tprintln(\"$(label(n)) is a leaf\")\nend\nfor n in internals(tree)\n\tprintln(\"$(label(n)) is an internal node\")\nend\nmap(label, nodes(tree)) == union(\n\tmap(label, leaves(tree)), \n\tmap(label, internals(tree))\n)","category":"page"},{"location":"Iteration/#A-note-on-speed","page":"Iteration","title":"A note on speed","text":"","category":"section"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"Iterating through tree using nodes(tree) will be faster than using POT(tree). This is mainly because of my inability to write an efficient iterator: currently, POT will allocate a number of times that is proportional to the size of the tree. Below is a simple example where we define functions that count the number of nodes in a tree:","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"using TreeTools # hide\ncount_nodes_pot(tree) = sum(x -> 1, POT(tree)) # Traversing the tree in post-order while summing 1\ncount_nodes_arbitrary(tree) = sum(x -> 1, nodes(tree)) # Arbitrary order\nnothing # hide","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"These two functions obviously give the same result, but not with the same run time. Here, we try it on the example/tree_10.nwk file: ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"tree = read_tree(\"../../examples/tree_10.nwk\")\nusing BenchmarkTools\n@btime count_nodes_pot(tree)\n@btime count_nodes_arbitrary(tree)","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"If a fast post-order is needed, the only solution in the current state of TreeTools is to \"manually\" program it.  The code below defines a more efficient to count nodes, traversing the tree in post-order. ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"function count_nodes_eff_pot(n::TreeNode) # this counts the number of nodes below `n`\n\tcnt = 0\n\tfor c in children(n)\n\t\tcnt += count_nodes_eff_pot(c) # \n\tend\n\treturn cnt + 1\nend\n\nfunction count_nodes_eff_pot(tree::Tree)\n\treturn count_nodes_eff_pot(tree.root)\nend\nnothing # hide","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"This will run faster than count_nodes_pot, and does not allocate.  For counting nodes, this is really overkill, and one could just call length(nodes(tree)).  In particular, traversing the tree in a precise order does not matter at all.  But for more complex use case, writing short recursive code as above does not add a lot of complexity. ","category":"page"},{"location":"Iteration/","page":"Iteration","title":"Iteration","text":"@btime count_nodes_eff_pot(tree)","category":"page"},{"location":"basic_concepts/#Basic-concepts","page":"Basic concepts","title":"Basic concepts","text":"","category":"section"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"To introduce basic concepts and data structures used in TreeTools, we will use the small tree given by this Newick string: \"((A:1,B:1)AB:2,C:3)R;\". To obtain a tree from the string, run the following code in a julia REPL: ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"using TreeTools \nnwk = \"((A:1,B:1)AB:2,C:3)R;\"\ntree = parse_newick_string(nwk)","category":"page"},{"location":"basic_concepts/#TreeNode","page":"Basic concepts","title":"TreeNode","text":"","category":"section"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"At the basic level, the tree is represented by a set of linked TreeNode structures. A node n contains the following information: ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"ancestor(n) returns the node above n. If n is the root, ancestor(n) returns nothing. \nchildren(n) returns an array containing all the nodes below n. If n is a leaf, children(n) is empty. \nlabel(n) returns the label of n, which also serves as an identifier of n in many TreeTools functions. See the warning below. \nbranch_length(n) returns the length of the branch above n as a Float64. If n is the root or if it does not have a branch length, it returns missing. \ndata(n) returns data attached to n, see TreeNodeData\nisroot(n) and isleaf(n) are boolean functions with explicit behavior. ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"warning: Node labels\nTreeTools generally uses the label of nodes as an identifier. This is visible in the Tree structure which uses node labels for indexing. Another example is the equality between TreeNode objects n1 == n2, which simply falls back to label(n1) == label(n2). For this reason, it is strongly discouraged to directly change the label of a node, e.g. by doing something like n.label = mylabel. A function label! is provided for that, called like this: label!(tree, n, mylabel). This makes sure that the struct tree is informed about the label change. ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"danger: Loops in the tree\nTreeTools does not actively enforce the fact that trees do not have loops. That is, if you try to, you can perfectly create a state where e.g. a node is its own ancestor. This will of course result in a lot of issues. I'd like to enforce the absence of loops at some point, but for now it's up to the user to be careful.  ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"The illustration below is a summary of the TreeNode object.  (Image: TreeNode_illustration)","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"Each TreeNode can be accessed by directly indexing into the tree: ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"AB = tree[\"AB\"]","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"Testing this on the above example would give: ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"println(\"The ancestor of $(label(AB)) is $(label(ancestor(AB))), at distance $(branch_length(AB))\")\nprintln(\"Children of $(label(AB)): \", map(label, children(AB)))\nisleaf(AB)\nmap(isleaf, children(AB))\nisroot(ancestor(AB))","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"Changing the value of the branch length or of the data attached to a node is done using the branch_length! and data! functions: ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"branch_length!(AB, 4.)\nprintln(\"The distance from $(label(AB)) to $(label(ancestor(AB))) is now $(branch_length(AB))\")","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"note: Branches\nTreeTools has no structure or type to represent branches.  Since only rooted trees are considered, it is natural for each node to \"own\" the branch above it.  As a result, informations about branches are expected  to be stored on the node below, as is the case for the branch length.","category":"page"},{"location":"basic_concepts/#TreeNodeData","page":"Basic concepts","title":"TreeNodeData","text":"","category":"section"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"TreeTools gives the possibility to attach data to nodes.  The TreeNode type is parametric: if data of type D is attached to a node, its type will be TreeNode{D}.  Children and ancestor of a TreeNode{D} object must also be of the TreeNode{D} type.  This implies that all nodes in the tree must have the same type of data attached to them. ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"The data type D has to be a subtype of the abstract type TreeNodeData.  The creation of nodes with a given data type is controlled by the node_data_type keyword argument in functions like parse_newick_string or read_tree (see the Reading and writing page).  Two subtypes of TreeNodeData are already implemented in TreeTools. ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"EmptyData is a data type containing nothing. Use it if you do not want to attach any data to nodes. It is used by default when creating tree nodes. \nMiscData is a wrapper around Dict, allowing arbitrary data to be stored","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"using TreeTools # hide\ntree = parse_newick_string(\"((A:1,B:1)AB:2,C:3)R;\", node_data_type = MiscData)\nA = tree[\"A\"]\ntypeof(A)\ndat = data(A)\ndat[1] = 2; dat[\"Hello\"] = \"world!\";\ndata(A)\ndata(A)[\"Hello\"]","category":"page"},{"location":"basic_concepts/#Custom-data-type","page":"Basic concepts","title":"Custom data type","text":"","category":"section"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"One can of course create arbitrary subtypes of TreeNodeData.  The only requirement for a custom data type D is that the call D() returns a valid instance of the type.  This is used when initially constructing the tree.  Below is an example of a custom Sequence type.  Note that if you actually want to use biological sequences, I encourage the use of the BioSequences.jl package. ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"using TreeTools # hide\nBase.@kwdef mutable struct Sequence <: TreeNodeData # Create a custom data type\n\tseq :: String = \"\"\n\tseq_type :: Symbol = :dna\nend\ntree = parse_newick_string(\"((A:1,B:1)AB:2,C:3)R;\", node_data_type = Sequence)\ntypeof(tree[\"C\"])\ndata!(tree[\"C\"], Sequence(seq = \"ACGT\"))\ndata(tree[\"C\"]).seq\ndata(tree[\"C\"]).seq_type","category":"page"},{"location":"basic_concepts/#Tree","page":"Basic concepts","title":"Tree","text":"","category":"section"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"In principle, access to one TreeNode object is enough to perform any operation on the tree.  However, in practice, it is often convenient to see the tree as a concept on its own, and not to see it through one of its nodes.  This is why TreeTools uses the Tree structure, which is basically a list of TreeNode objects.  Tree objects provide some specific methods: ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"nodes and leaves and internals respectively return iterators over all nodes, leaves and internal nodes of the tree, in an arbitrary order","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"println(\"Internal nodes: \", map(label, internals(tree)))\nprintln(\"Leaves: \", map(label, leaves(tree)))","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"the call tree[label] will return the tree node with the corresponding label. Presence of a node in tree can be checked with in(node, tree) or in(label, tree)","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"in(\"AB\", tree)\nin(tree[\"AB\"], tree)\nin(\"MyCat\", tree)","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"label returns the name of the tree. It can be changed the label! method\nroot returns the root of the tree","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"Trees are construceted automatically from Newick strings when using functions such as parse_newick_string or read_tree (see Reading and writing).  To construct a tree from a Tree from a TreeNode, use the node2tree function. Note that this is only intended to be used on root nodes: a warning will be produced if not. ","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"using TreeTools # hide\ntree = parse_newick_string(\"((A:1,B:1)AB:2,C:3)R;\") # hide\nR = tree[\"R\"]\ntree2 = node2tree(R)","category":"page"},{"location":"basic_concepts/","page":"Basic concepts","title":"Basic concepts","text":"warning: Copying a tree\nThe call tree2 = node2tree(tree.root) will produce another tree that shares nodes with tree.. This is usually not a good way to copy a tree, since the actual tree nodes are not copied. Any modification of the nodes of tree will also modify those of tree2. To make an independent copy, simply call copy(tree). ","category":"page"},{"location":"modifying_the_tree/#Modifying-the-tree","page":"Modifying the tree","title":"Modifying the tree","text":"","category":"section"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"On some occasions, it can be useful to modify a phylogenetic tree, e.g. removing some clades or branches.  TreeKnit offers a few methods for this: ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"prune! and prunesubtree! for pruning a clade. \ngraft! for grafting a node onto a tree.\ninsert! for inserting an internal node on an existing branch of a tree. \ndelete! to delete an internal node while keeping the nodes below it. ","category":"page"},{"location":"modifying_the_tree/#Pruning","page":"Modifying the tree","title":"Pruning","text":"","category":"section"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"There are two functions to prune nodes: prune! and prunesubtree!.  They behave exactly the same except for the return value: prune! returns the prunde clade as a Tree object, while prunesubtree! just returns its root as a TreeNode object.  Both also return the previous ancestor of the pruned clade.  Let's see an example","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"using TreeTools # hide\ntree = parse_newick_string(\"(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;\")","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"Let's assume that we realized leaves X1 and X2 are really a weird outlier in our tree.  We want to get rid of them. ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"tx, a = prune!(tree, \"X1\", \"X2\"); \ntx\ntree","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"When called on a list of labels, prune! finds the MRCA of the input labels and prunes it from the tree.  Here, lca(tree, X1, X2) is internal node X, which is removed from the tree.  Note that cutting the branch above X will leave the internal node BX with a single child.  By default, prune! also removes singletons from the input tree.","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"map(label, nodes(tree)) # `BX` is not in there","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"This behavior can be changed with the remove_singletons keyword argument: ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"let\n\ttree = parse_newick_string(\"(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;\")\n\tprune!(tree, \"X\"; remove_singletons=false)\n\tmap(label, nodes(tree))\nend","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"The prunesubtree! method does exactly the same as prune!, but returns the root of the pruned clade as a TreeNode, without converting it to a Tree.  Thus the two calls are equivalent: ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"using TreeTools # hide\ntree = parse_newick_string(\"(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;\") # hide\ntx = prune!(tree, \"X\")[1] # or ... \ntree = parse_newick_string(\"(A:1.,(B:1.,(X1:0.,X2:0.)X:5.)BX:1.)R;\") # hide\ntx = let\n\tr, a = prunesubtree!(tree, \"X\")\n\tnode2tree(r)\nend","category":"page"},{"location":"modifying_the_tree/#Deleting-a-node","page":"Modifying the tree","title":"Deleting a node","text":"","category":"section"},{"location":"modifying_the_tree/#Grafting","page":"Modifying the tree","title":"Grafting","text":"","category":"section"},{"location":"modifying_the_tree/#Inserting-a-node","page":"Modifying the tree","title":"Inserting a node","text":"","category":"section"},{"location":"modifying_the_tree/#TreeNode-level-functions","page":"Modifying the tree","title":"TreeNode level functions","text":"","category":"section"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"All the methods above take a Tree as a first argument.  As described in Basic concepts, the actual information about the tree is contained in TreeNode objects, while the Tree is basically a wrapper around TreeNodes.  Thus, a method like prune! has to do two things: ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"cut the ancestry relation between two TreeNode objects.\nupdate the Tree object in a consistent way. ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"The first part is where the \"actual\" pruning happens, and is done by the prunenode! function, which just takes a single TreeNode as input.  TreeTools has similar \"TreeNode level\" methods (not exported): ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"prunenode!(n::TreeNode): cut the relation between n and its ancestor\ngraftnode!(r::TreeNode, n::TreeNode): graft n onto r. \ndelete_node!(n::TreeNode): delete cut the relation between n and its ancestor a, but re-graft the children of n onto a. \ninsert_node!(c, a, s, t): insert s::TreeNode between c and a, at height t on the branch. ","category":"page"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"These methods only act on TreeNode objects and do not care about the consistency with the Tree.  In most cases, it's more practical to call the Tree level methods.  However, if speed is important, it might be better to use them. ","category":"page"},{"location":"modifying_the_tree/#Other-useful-functions","page":"Modifying the tree","title":"Other useful functions","text":"","category":"section"},{"location":"modifying_the_tree/#Remove-singletons","page":"Modifying the tree","title":"Remove singletons","text":"","category":"section"},{"location":"modifying_the_tree/","page":"Modifying the tree","title":"Modifying the tree","text":"remove_internal_singletons!","category":"page"},{"location":"modifying_the_tree/#Delete-insignificant-branches","page":"Modifying the tree","title":"Delete insignificant branches","text":"","category":"section"},{"location":"#TreeTools.jl","page":"Home","title":"TreeTools.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"TreeTools is a package to allow manipulation and simple operations on rooted phylogenetic or genealogic trees.  It started off as a dependency of another package TreeKnit, but can in principle be used for any problem involving trees. ","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"You can simply install TreeTools using the julia package manager (if you don't have julia, you can get it from here): ","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Pkg\nPkg.add(\"TreeTools\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"You should now be able to use using TreeKnit from inside julia and follow the rest of the documentation. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"info: Info\nThe documentation is being written: more things to come! ","category":"page"},{"location":"useful_functions/#Useful-functions","page":"Useful functions","title":"Useful functions","text":"","category":"section"},{"location":"useful_functions/#Copy,-convert","page":"Useful functions","title":"Copy, convert","text":"","category":"section"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"To make an independent copy of a tree, simply call copy. ","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"using TreeTools # hide\ntree = parse_newick_string(\"((A:1,B:1)AB:2,C:3)R;\");\ntree_copy = copy(tree);\nlabel!(tree_copy, \"A\", \"Alfred\") # relabel node A\ntree_copy\ntree","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"The convert function allows one to change the data type attached to nodes: ","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"typeof(tree)\ndata(tree[\"A\"])\ntree_with_data = convert(Tree{MiscData}, tree);\ntypeof(tree_with_data)\ndata(tree_with_data[\"A\"])[\"Hello\"] = \" world!\"","category":"page"},{"location":"useful_functions/#MRCA,-divergence-time","page":"Useful functions","title":"MRCA, divergence time","text":"","category":"section"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"The most recent common ancestor between two nodes or more is found using the function lca: ","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"lca(tree[\"A\"], tree[\"B\"]) # simplest form\nlca(tree, \"A\", \"B\") # lca(tree, labels...)\nlca(tree, \"A\", \"B\", \"C\") # takes a variable number of labels as input\nlca(tree, \"A\", \"AB\") # This is not restricted to leaves","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"To compute the distance or divergence time between two tree nodes, use distance.  The topological keyword allows computing the number of branches separating two nodes. ","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"distance(tree, \"A\", \"C\")\ndistance(tree[\"A\"], tree[\"C\"]; topological=true) ","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"The function is_ancestor tells you if one node is found among the ancestors of another.  This uses equality between TreeNode, which simply compares labels, see Basic concepts","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"is_ancestor(tree, \"A\", \"C\")\nis_ancestor(tree, \"R\", \"A\")","category":"page"},{"location":"useful_functions/#Distance-between-trees","page":"Useful functions","title":"Distance between trees","text":"","category":"section"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"The distance function also lets you compute the distance between two trees.  For now, only the Robinson-Foulds distance is implemented, but more could come. ","category":"page"},{"location":"useful_functions/","page":"Useful functions","title":"Useful functions","text":"using TreeTools # hide\nt1 = parse_newick_string(\"((A,B,D),C);\")\nt2 = parse_newick_string(\"((A,(B,D)),C);\")\ndistance(t1, t2)\ndistance(t1, t2; scale=true)","category":"page"},{"location":"IO/#Reading-and-writing","page":"Reading and writing","title":"Reading and writing","text":"","category":"section"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"For now, TreeTools only handles the Newick format.  Functions are quite basic at this stage. ","category":"page"},{"location":"IO/#Reading","page":"Reading and writing","title":"Reading","text":"","category":"section"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"If you have a variable containing a Newick string, simply call parse_newick_string to return a tree.  To read from a file, use read_tree.  Here is an example with the example/tree_10.nwk file: ","category":"page"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"using TreeTools # hide\ntree = read_tree(\"../../examples/tree_10.nwk\")","category":"page"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"The documentation reproduced below gives more information: ","category":"page"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"TreeTools.read_tree","category":"page"},{"location":"IO/#TreeTools.read_tree","page":"Reading and writing","title":"TreeTools.read_tree","text":"read_tree(\n\tnwk_filename::AbstractString;\n\tnode_data_type=DEFAULT_NODE_DATATYPE, label=default_tree_label(), force_new_labels=false\n)\nread_tree(\n\tio::IO;\n\tnode_data_type=DEFAULT_NODE_DATATYPE, label=default_tree_label(), force_new_labels=false\n)\n\nRead Newick file and create a Tree{node_data_type} object from it. The input file can contain multiple Newick strings on different lines. The output will then be an array of Tree objects.\n\nnode_data_type must be a subtype of TreeNodeData, and the call node_data_type() must return a valid instance of node_data_type. See ?TreeNodeData for implemented types.\n\nUse force_new_labels=true to force the renaming of all internal nodes. By default the tree will be assigned a default_tree_label(), however the label of the  tree can also be assigned with the label parameter. \n\nIf you have a variable containing a Newick string and want to build a tree from it, use parse_newick_string instead.\n\nNote on labels\n\nThe Tree type identifies nodes by their labels. This means that labels have to be unique. For this reason, the following is done when reading a tree:\n\nif an internal node does not have a label, a unique one will be created of the form  \"NODE_i\"\nif a node has a label that was already found before in the tree, a random identifier  will be appended to it to make it unique. Note that the identifier is created using  randstring(8), unicity is technically not guaranteed.\nif force_new_labels is used, a unique identifier is appended to node labels\nif node labels in the Newick file are identified as confidence/bootstrap values, a random  identifier is appended to them, even if they're unique in the tree. See  ?TreeTools.isbootstrap to see which labels are identified as confidence values.\n\n\n\n\n\n","category":"function"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"read_tree will also read files containing several Newick strings, provided they are on separate lines.  It then returns an array of Tree objects. ","category":"page"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"If internal nodes of a Newick string do not have names, TreeTools will by default give them names of the form NODE_i with i::Int.  This happens during parsing of the Newick string, in the parse_newick! function.  This label is technically not guaranteed to be unique: the Newick string may also contain nodes with the same name.  In some cases, it is thus necessary to create a unique identifier for a node.  This is done by creating a random string obtained with the call Random.randstring(8), and happens at a later stage, when calling the node2tree function (see the section about Tree).  This happens when: ","category":"page"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"the node label is found to be a bootstrap value (see ?TreeTools.isbootstrap). \nthe option force_new_labels is used when calling read_tree. This is useful if some internal nodes of the Newick string have redundant names. \nfor some reason, the node does not yet have a label. ","category":"page"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"There are about 2cdot 10^14 strings of length 8 (alphabetic + numeric characters), so this should be fine for most problems. A quick calculation shows that for a tree of 1000 leaves, the probability of obtaining two equal identifiers for different nodes is sim 2 cdot 10^-9, which is probably acceptable for most applications. If you think it's not enough, I can add a handle to let user create longer strings, or solve this in a more elegant way. ","category":"page"},{"location":"IO/#Writing","page":"Reading and writing","title":"Writing","text":"","category":"section"},{"location":"IO/","page":"Reading and writing","title":"Reading and writing","text":"To write t::Tree to a Newick file, simply call write(filename, t).  If you want to append to a file, call write(filename, t, \"a\").  Note that write(filename, t) adds a newline '\\n' character at the end of the Newick string.  This is done in case other trees have to be added to the file. ","category":"page"}]
}
