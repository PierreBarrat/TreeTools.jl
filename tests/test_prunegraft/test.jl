## Testing pruning
global root_1 = read_newick("tree1.nwk")
@testset "Pruning" begin
	# Pruning with modification
	root = deepcopy(root_1)
	global A = prunenode!(root.child[1].child[1])[1]
	root_ref = read_newick("test_prunegraft/tree1_Apruned.nwk")
    @test root == root_ref
    # Pruning with copy
	root = deepcopy(root_1)
	global A2 = prunenode(root.child[1].child[1])[1]
	@test root == root_1 && A == A2	
end 


@testset "Grafting" begin
	root = deepcopy(root_1)
	A = prunenode!(root.child[1].child[1])[1]
	graftnode!(root.child[2].child[1], A);
	@test root == read_newick("tree_grafttest1.nwk")
end


@testset "Deleting" begin
	root = deepcopy(root_1)
	temp = delete_node!(root.child[1])
	@test temp == root && root == read_newick("tree_del1.nwk") 
end

@testset "Deleting branches" begin
    root = read_newick("test_prunegraft/tree_testnullbranches.nwk")
    delete_null_branches!(root)
    @test root == read_newick("test_prunegraft/tree_testnullbranches_.nwk")
end

	