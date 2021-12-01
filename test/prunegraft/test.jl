using Test
using TreeTools

println("##### prunegraft #####")
global root_1 = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree1.nwk")
@testset "Pruning" begin
	# Pruning with modification
	root = deepcopy(root_1)
	global A = prunenode!(root.child[1].child[1])[1]
	root_ref = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree1_Apruned.nwk")
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
	@test root == TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_grafttest1.nwk")
end


@testset "Deleting" begin
	root = deepcopy(root_1)
	temp = delete_node!(root.child[1])
	@test temp == root && root == TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_del1.nwk")
end

@testset "Deleting branches" begin
    root = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_testnullbranches.nwk")
    TreeTools.delete_null_branches!(root)
    @test root == TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_testnullbranches_.nwk")
end


nwk1 = "(A,(B,(C,D)))"
t1 = node2tree(TreeTools.parse_newick(nwk1))
