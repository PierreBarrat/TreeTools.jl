## TODO
# - read_newick: if spaces in file, an error is produced. fix it, test it
# Currently, I think I can graft a tree on itself. Obvious problems with this. 


## Testing equality operator
root_1 = read_newick("tree1.nwk")
root_2 = read_newick("tree1_reordered.nwk")
@testset "Equality `==`" begin
	@test root_1 == root_2
end

# Testing ancestors
@testset "Ancestors" begin
    root_1 = read_newick("tree1.nwk")
    @test isancestor(root_1, root_1.child[1])
    @test isancestor(root_1, root_1.child[1].child[1])
    @test !isancestor(root_1.child[1],root_1.child[2])
    root_2 = read_newick("tree2.nwk")
    @test lca((root_2.child[1].child[1], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1].child[1], root_2.child[1].child[1].child[2], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1], root_2.child[2])).label == "ABCD"
end

# Testing clades
@testset "Clades" begin
	root_1 = read_newick("tree1.nwk")
	tree1 = node2tree(root_1)
	cl1 = node_clade(root_1.child[1])
	cl1_ = tree_clade(tree1, node_findkey(root_1.child[1], tree1))
	@test mapreduce(x->cl1[x] == tree1.nodes[cl1_[x]], *, 1:3)
	cl1 = node_leavesclade(root_1.child[1])
	cl1_ = tree_leavesclade(tree1, node_findkey(root_1.child[1], tree1))
	@test mapreduce(x->cl1[x] == tree1.leaves[cl1_[x]], *, 1:2)
end

# # Testing grafting
# @testset "Grafting" begin
#     graftnode!(root, root.child[1], A, 2., insert_label = "AB")
#     @test root == root_1

# 	global A = prunenode!(root.child[2].child[2])
# 	graftnode!(root, root.child[1], A, 1., insert_label = "Insert")
# 	root_ref = read_newick("test_objectmethods/tree1_Agrafted.nwk")
# 	@test root == root_ref

# 	global root = deepcopy(root_1)
# 	global A = prunenode!(root.child[1].child[1])
# 	@test_throws ErrorException graftnode!(root, root.child[1], A, 5.)
# 	@test_throws ErrorException graftnode!(root.child[2], root.child[1], A, 2.)	
# end