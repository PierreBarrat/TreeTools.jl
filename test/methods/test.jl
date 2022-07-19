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

@testset "Copy type" begin
	t1 = Tree(TreeNode(MiscData(Dict(1=>2))))
	tc = copy(t1)
	@test tc.root.data[1] == 2
	t1.root.data[1] = 3
	@test tc.root.data[1] == 2
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
	t1 = Tree(TreeNode(MiscData(Dict(1=>2))))
	# No op
	@test convert(Tree{MiscData}, t1) === t1
	@test convert(Tree{MiscData}, t1).root.data === t1.root.data

	# Converting to EmptyData and back
	t2 = convert(Tree{TreeTools.EmptyData}, t1)
	t3 = convert(Tree{MiscData}, t2)
	@test typeof(t2) == Tree{TreeTools.EmptyData}
	@test t2.root.data == TreeTools.EmptyData()

	@test typeof(t3) == Tree{TreeTools.MiscData}
	@test !haskey(t3.root.data, 1)

	###

	t1 = Tree(TreeNode(TreeTools.EmptyData()))
	# No op
	@test convert(Tree{TreeTools.EmptyData}, t1) === t1

	# Converting to MiscData and back
	t2 = convert(Tree{TreeTools.MiscData}, t1)
	@test typeof(t2) == Tree{TreeTools.MiscData}
	@test isempty(t2.root.data)

	@test typeof(convert(Tree{TreeTools.EmptyData}, t2)) == Tree{TreeTools.EmptyData}
end

nwk = "(A:3,(B:1,C:1):2);"
@testset "Distance" begin
	t = parse_newick_string(nwk)
	# Branch length
	@test distance(t, "A", "B") == 6
	@test distance(t.lnodes["A"], t.lnodes["B"]) == 6
	@test distance(t, "A", "B") == distance(t, "A", "C")
	@test distance(t.root, t.lnodes["A"]) == 3
	# Topological
	@test distance(t.root, t.lnodes["A"]; topological=true) == 1
	@test distance(t, "A", "B"; topological=true) == distance(t, "A", "C"; topological=true)
	@test distance(t, "A", "B"; topological=true) == 3
	for n in nodes(t)
		@test distance(t[n.label], t[n.label]; topological=true) == 0
		@test distance(t[n.label], t[n.label]; topological=false) == 0
	end
	# tests below can be removed when `divtime` is removed
	@test divtime(t.lnodes["A"], t.lnodes["B"]) == 6
	@test divtime(t.root, t.lnodes["A"]) == 3
end
