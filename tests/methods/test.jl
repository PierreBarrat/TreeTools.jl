println("##### methods #####")

using Test
using TreeTools


## Testing equality operator
root_1 = TreeTools.read_newick("methods/tree1.nwk")
root_2 = TreeTools.read_newick("methods/tree1_reordered.nwk")
@testset "Equality `==`" begin
	@test root_1 == root_2
end

@testset "node2tree" begin
	@test typeof(node2tree(root_1)) <: Tree
	@test typeof(node2tree(root_2)) <: Tree
end

# Testing ancestors
@testset "Ancestors" begin
    root_1 = TreeTools.read_newick("methods/tree1.nwk")
    @test TreeTools.isancestor(root_1, root_1.child[1])
    @test TreeTools.isancestor(root_1, root_1.child[1].child[1])
    @test !TreeTools.isancestor(root_1.child[1],root_1.child[2])
    root_2 = TreeTools.read_newick("methods/tree2.nwk")
    @test lca((root_2.child[1].child[1], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1].child[1], root_2.child[1].child[1].child[2], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1], root_2.child[2])).label == "ABCD"
end

@testset "Count" begin
	t1 = node2tree(root_1)
end

