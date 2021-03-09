println("##### test_objectmethods #####")

using Test
using TreeTools


## Testing equality operator
root_1 = TreeTools.read_newick("test_objectmethods/tree1.nwk")
root_2 = TreeTools.read_newick("test_objectmethods/tree1_reordered.nwk")
@testset "Equality `==`" begin
	@test root_1 == root_2
end

# Testing ancestors
@testset "Ancestors" begin
    root_1 = TreeTools.read_newick("test_objectmethods/tree1.nwk")
    @test isancestor(root_1, root_1.child[1])
    @test isancestor(root_1, root_1.child[1].child[1])
    @test !isancestor(root_1.child[1],root_1.child[2])
    root_2 = TreeTools.read_newick("test_objectmethods/tree2.nwk")
    @test lca((root_2.child[1].child[1], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1].child[1], root_2.child[1].child[1].child[2], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1], root_2.child[2])).label == "ABCD"
end

