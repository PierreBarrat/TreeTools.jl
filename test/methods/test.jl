# println("##### methods #####")

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
    @test TreeTools.is_ancestor(root_1, root_1.child[1])
    @test TreeTools.is_ancestor(root_1, root_1.child[1].child[1])
    @test !TreeTools.is_ancestor(root_1.child[1],root_1.child[2])
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
	t3 = copy(t1, force_new_tree_label=true)
	t4 = copy(t1, label="tree_4")
	@test typeof(t1) == typeof(t2)
	prunesubtree!(t2, ["A"])
	@test haskey(t1.lnodes, "A")
	@test !haskey(t2.lnodes, "A")
	@test t1.label == t2.label
	@test t1.label != t3.label
	@test t1.label != t4.label
	@test t4.label == "tree_4"
end


@testset "Convert" begin
	t1 = Tree(TreeNode(MiscData(Dict(1=>2))))
	# No op
	@test convert(Tree{MiscData}, t1) === t1
    @test convert(MiscData, t1) === t1
	@test convert(Tree{MiscData}, t1).root.data === t1.root.data
    @test convert(MiscData, t1).root.data === t1.root.data

	# Converting to EmptyData and back
	t2 = convert(Tree{TreeTools.EmptyData}, t1)
	t3 = convert(MiscData, t2)
	@test typeof(t2) == Tree{TreeTools.EmptyData}
	@test t2.root.data == TreeTools.EmptyData()

	@test typeof(t3) == Tree{TreeTools.MiscData}
	@test !haskey(t3.root.data, 1)

	###

	t1 = Tree(TreeNode(TreeTools.EmptyData()))
	# No op
	@test convert(TreeTools.EmptyData, t1) === t1

	# Converting to MiscData and back
	t2 = convert(Tree{TreeTools.MiscData}, t1)
	@test typeof(t2) == Tree{TreeTools.MiscData}
	@test isempty(t2.root.data)

	@test typeof(convert(Tree{TreeTools.EmptyData}, t2)) == Tree{TreeTools.EmptyData}

	##check convert will keep tree labels by default
	t3 = Tree(TreeNode(TreeTools.EmptyData()))
	t3.label = "tree3"
	#while converting to MiscData and back
	@test convert(TreeTools.MiscData, t3).label === "tree3"
	@test convert(Tree{TreeTools.EmptyData}, t3).label === "tree3"
	##check label can be changed if specified
	t3 = Tree(TreeNode(TreeTools.EmptyData()))
	t3.label = "tree3"
	@test convert(Tree{TreeTools.MiscData}, t3; label="tree4").label === "tree4"
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

## The tests below depend on the way internal nodes are labelled
## They may need to be rewritten
nwk = "(A,(B,C));"
@testset "Spanning tree 1" begin
	t = parse_newick_string(nwk)
	@test isempty(TreeTools.branches_in_spanning_tree(t, "A"))
	@test sort(TreeTools.branches_in_spanning_tree(t, "A", "B")) == sort(["A", "B", "NODE_2"])
	@test sort(TreeTools.branches_in_spanning_tree(t, "B", "C")) == sort(["B", "C"])
end

nwk = "((A,B),(D,(E,F,G)));"
@testset "Spanning tree 2" begin
	t = parse_newick_string(nwk)
	tmp = sort(TreeTools.branches_in_spanning_tree(t, "A", "E", "F"))
	@test tmp == sort(["A", "NODE_2", "E", "F", "NODE_4", "NODE_3"])
	@test isempty(TreeTools.branches_in_spanning_tree(t, "E"))
end

@testset "ladderize alphabetically" begin
	t1 = node2tree(TreeTools.parse_newick("((D,A,B),C)"; node_data_type=TreeTools.MiscData); label="t1")
	TreeTools.ladderize!(t1)
	@test write_newick(t1) == "(C,(A,B,D)NODE_2)NODE_1:0;"
end


@testset "Binarize" begin
	bl(t) = sum(skipmissing(map(x -> x.tau, nodes(t)))) # branch length should stay unchanged

	nwk = "(A,(B,C,D,E,(F,G,H)));"
	@testset "1" begin
		t = parse_newick_string(nwk)
		TreeTools.rand_times!(t)
		L = bl(t)
		z = TreeTools.binarize!(t; mode=:balanced)
		@test z == 4
		@test length(SplitList(t)) == 7
		@test isapprox(bl(t), L; rtol = 1e-14)
	end

	nwk = "(8:571.0,(((10:0.0,17:0.0)internal_1:12.8,(12:0.0,19:0.0)internal_2:12.5)internal_11:80.7,((6:26.3,(4:0.0,5:0.0)internal_7:22.0)internal_14:22.4,(1:12.5,3:12.5)internal_10:36.1,((11:0.0,20:0.0)internal_5:16.5,7:11.2,16:11.2,9:0.0,13:0.0,18:0.0,15:0.0)internal_13:23.1,(2:0.0,14:0.0)internal_4:42.1)internal_17:43.0)internal_18:477.0)internal_19:0;"
	@testset "2" begin
		t = parse_newick_string(nwk)
		L = bl(t)
		z = TreeTools.binarize!(t; mode=:balanced)
		@test length(nodes(t)) == 2*length(leaves(t)) - 1
		for n in nodes(t)
			@test length(children(n)) == 2 || isleaf(n)
		end
	end

end



@testset "Midpoint rooting" begin
	@testset "1" begin
		nwk = "(A,(B,(C,(D,(E,F)))));"
		t = parse_newick_string(nwk)
		TreeTools.rand_times!(t)
		TreeTools.root!(t, method=:midpoint, topological=true)
		for n in nodes(t)
			@test (n.isroot && ismissing(branch_length(n))) || (!n.isroot && !ismissing(branch_length(n)))
		end
		@test length(children(t.root)) == 2
		d1 = TreeTools.distance_to_deepest_leaf(t.root.child[1]; topological=true) + 1
		d2 = TreeTools.distance_to_deepest_leaf(t.root.child[2]; topological=true) + 1
		@test d1 == d2 || abs(d1-d2) == 1
	end


	@testset "2" begin
		nwk = "(A,(B,(C,(D,E))));"
		t = parse_newick_string(nwk)
		TreeTools.rand_times!(t)
		TreeTools.root!(t, method=:midpoint, topological=true)
		for n in nodes(t)
			@test (n.isroot && ismissing(branch_length(n))) || (!n.isroot && !ismissing(branch_length(n)))
		end
		@test length(children(t.root)) == 2
		d1 = TreeTools.distance_to_deepest_leaf(t.root.child[1]; topological=true) + 1
		d2 = TreeTools.distance_to_deepest_leaf(t.root.child[2]; topological=true) + 1
		@test d1 == d2 || abs(d1-d2) == 1
	end


	@testset "3" begin
		nwk = "(A,((B,(C,D)),E,F,(G,(H,I))));"
		t = parse_newick_string(nwk);
		TreeTools.rand_times!(t)
		TreeTools.root!(t, method = :midpoint)
		@test length(children(t.root)) == 2
		d1 = TreeTools.distance_to_deepest_leaf(t.root.child[1]; topological=false) + t.root.child[1].tau
		d2 = TreeTools.distance_to_deepest_leaf(t.root.child[2]; topological=false) + t.root.child[2].tau
		@test isapprox(d1, d2, rtol = 1e-10)
	end

	# Some Kingman tree
	nwk = "((3:42.39239447896236,9:42.39239447896236)internal_7:184.59454190028205,(((7:5.386265198881789,(4:3.4161799796066714,6:3.4161799796066714)internal_1:1.970085219275118)internal_3:13.350057070009068,(2:5.857739627778067,5:5.857739627778067)internal_4:12.878582641112791)internal_5:27.712331677710498,(10:33.43880444968331,(1:4.740041795143892,8:4.740041795143892)internal_2:28.69876265453942)internal_6:13.009849496918044)internal_8:180.53828243264306)internal_9:0;"
	@testset "4" begin
		t = parse_newick_string(nwk)
		TreeTools.root!(t; method=:midpoint)
		for n in nodes(t)
			@test isroot(n) || !ismissing(branch_length(n))
		end
		@test length(children(t.root)) == 2
		d1 = TreeTools.distance_to_deepest_leaf(t.root.child[1]; topological=false) + t.root.child[1].tau
		d2 = TreeTools.distance_to_deepest_leaf(t.root.child[2]; topological=false) + t.root.child[2].tau
		@test isapprox(d1, d2, rtol = 1e-10)
	end


	# Some sick tree by Marco
	@testset "5" begin
		nwk = "(A:0.0,B:0.0,C:0.0,D:0.0,E:0.0,F:0.0,G:0.0,H:0.0,I:0.0,J:0.0)ROOT;"
		t = parse_newick_string(nwk)
		@test_logs (:warn, r"") match_mode=:any TreeTools.root!(t; method=:midpoint) # should warn and do nothing
		@test label(t.root) == "ROOT"

		TreeTools.root!(t; method=:midpoint, topological=true) # should do nothing since root is already midpoint
		@test label(t.root) == "ROOT"

		branch_length!(t["A"], 1.)
		TreeTools.root!(t; method=:midpoint)
		@test length(children(t.root)) == 2
		@test in(t["A"], children(t.root))
	end


end

@testset "Tree measures" begin
	nwk1 = "((A,B),C);"
	nwk2 = "(A,(B,C));"
	nwk3 = "((A,B,D),C);"
	nwk4 = "(((A,B),D),C);"
	nwk5 = "(A,B,C,D);"

	t1 = node2tree(TreeTools.parse_newick(nwk1), label = "a")
	t2 = node2tree(TreeTools.parse_newick(nwk2), label = "b")
	t3 = node2tree(TreeTools.parse_newick(nwk3), label = "c")
	t4 = node2tree(TreeTools.parse_newick(nwk4), label = "d")
	t5 = node2tree(TreeTools.parse_newick(nwk5), label = "e")

	@testset "RF distance" begin
		@test TreeTools.RF_distance(t1, t2) == 2
	    @test TreeTools.RF_distance(t3, t4) == 1
	    @test TreeTools.RF_distance(t1, t2; normalize=true) == 1
	    @test TreeTools.RF_distance(t3, t4; normalize=true) == 1/3
	    @test_throws AssertionError TreeTools.RF_distance(t1, t3)
	end

	@testset "resolution value" begin
		@test TreeTools.resolution_value(t3) == (1/2)
	    @test TreeTools.resolution_value(t4) == 1
	    @test TreeTools.resolution_value(t5) == 0
	end
end



















