println("##### methods #####")

using Test
using TreeTools


## Testing equality operator
root_1 = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/methods/tree1.nwk")
root_2 = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/methods/tree1_reordered.nwk")
@testset "Equality `==`" begin
	@test root_1 == root_2
end

@testset "node2tree" begin
	@test typeof(node2tree(root_1)) <: Tree
	@test typeof(node2tree(root_2)) <: Tree
end

# Testing ancestors
@testset "Ancestors" begin
    root_1 = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/methods/tree1.nwk")
    @test TreeTools.isancestor(root_1, root_1.child[1])
    @test TreeTools.isancestor(root_1, root_1.child[1].child[1])
    @test !TreeTools.isancestor(root_1.child[1],root_1.child[2])
    root_2 = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/methods/tree2.nwk")
    @test lca((root_2.child[1].child[1], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1].child[1], root_2.child[1].child[1].child[2], root_2.child[1].child[2])).label == "ABC"
    @test lca((root_2.child[1].child[1], root_2.child[2])).label == "ABCD"
end

@testset "Count" begin
	t1 = node2tree(root_1)
	@test count(isleaf, t1) == 4
	@test count(n -> n.label[1] == 'A', t1) == 3
	@test count(isleaf, t1.lnodes["AB"]) == 2
	@test count(n -> n.label[1] == 'A', t1.lnodes["AB"]) == 2
end

@testset "Copy" begin
	t1 = node2tree(root_1)
	t2 = copy(t1)
	@test typeof(t1) == typeof(t2)
	prunesubtree!(t2, ["A"])
	@test haskey(t1.lnodes, "A")
	@test !haskey(t2.lnodes, "A")
end

@testset "Convert" begin
	t1 = node2tree(root_1)
	# Converting to EmptyData and back
	t2 = convert(Tree{TreeTools.EmptyData}, t1)
	@test typeof(t2) == Tree{TreeTools.EmptyData}
	@test typeof(convert(Tree{TreeTools.MiscData}, t2)) == Tree{TreeTools.MiscData}

	# Converting to MiscData and back
	t2 = convert(Tree{TreeTools.MiscData}, t1)
	@test typeof(t2) == Tree{TreeTools.MiscData}
	@test typeof(convert(Tree{TreeTools.EmptyData}, t2)) == Tree{TreeTools.EmptyData}
end

