## TODO
# - read_newick: if spaces in file, an error is produced. fix it, test it
# Currently, I think I can graft a tree on itself. Obvious problems with this. 


## Testing equality operator
root_1 = read_newick("tree1.nwk")
root_2 = read_newick("tree1_reordered.nwk")
@testset "Equality `==`" begin
	@test root_1 == root_2
end

## Testing pruning
root_1 = read_newick("tree1.nwk")
root = deepcopy(root_1)
@testset "Pruning" begin
	global A = prunenode!(root.child[1].child[1])
	root_ref = read_newick("test_objectmethods/tree1_Apruned.nwk")
    @test root == root_ref
end 


# Testing grafting
@testset "Grafting" begin
    graftnode!(root, root.child[1], A, 2., insert_label = "AB")
    @test root == root_1

	global A = prunenode!(root.child[2].child[2])
	graftnode!(root, root.child[1], A, 1., insert_label = "Insert")
	root_ref = read_newick("test_objectmethods/tree1_Agrafted.nwk")
	@test root == root_ref

	global root = deepcopy(root_1)
	global A = prunenode!(root.child[1].child[1])
	@test_throws ErrorException graftnode!(root, root.child[1], A, 5.)
	@test_throws ErrorException graftnode!(root.child[2], root.child[1], A, 2.)	
end
