using Test
using TreeTools

print("empty node: \n")
n = TreeNode()
empty_t = node2tree(n);
print_tree_ascii(IO, empty_t)

print("single node: \n")
t1 = parse_newick_string("A:1")
print_tree_ascii(IO, t1)

print("nodes with branch length: \n")
t1 = parse_newick_string("(A:1, B:2)R:0")
print_tree_ascii(IO, t1)

print("unnamed nodes and no branch length: \n")
t2 = parse_newick_string("(A:1,)")
print_tree_ascii(IO, t2)

print("unnamed node with branch length: \n")
t2 = parse_newick_string("(A:1,:2):0")
print_tree_ascii(IO, t2)

print("node with no branch length: \n")
t2 = parse_newick_string("(A:1, B)R")
print_tree_ascii(IO, t2)

print("tree with branch lengths from nwk file")
t3 = node2tree(
    TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/iterators/tree1.nwk")
)
print_tree_ascii(IO, t3)
