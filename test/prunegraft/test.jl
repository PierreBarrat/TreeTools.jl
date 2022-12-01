using Test
using TreeTools


@testset "TreeNode level functions" begin
	root_1 = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree1.nwk")

	@testset "Pruning (node)" begin
		# Pruning with modification
		root = deepcopy(root_1)
		global A = TreeTools.prunenode!(root.child[1].child[1])[1]
		root_ref = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree1_Apruned.nwk")
	    @test root == root_ref
	    # Pruning with copy
		root = deepcopy(root_1)
		global A2 = TreeTools.prunenode(root.child[1].child[1])[1]
		@test root == root_1 && A == A2
	end


	@testset "Grafting (node)" begin
		root = deepcopy(root_1)
		A = TreeTools.prunenode!(root.child[1].child[1])[1]
		TreeTools.graftnode!(root.child[2].child[1], A);
		@test root == TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_grafttest1.nwk")
	end

	@testset "Deleting" begin
		root = deepcopy(root_1)
		temp = delete_node!(root.child[1])
		@test temp == root && root == TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_del1.nwk")
	end
end


@testset "Grafting new node onto tree" begin
	nwk = "((A:1,B:1)AB:2,(C:1,D:1)CD:2)R;"
	t = parse_newick_string(nwk)

	# 1
	E = TreeNode(label = "E", tau = 4.)
	tc = copy(t)
	graft!(tc, E, "AB")
	@test sort(map(label, children(tc["AB"]))) == ["A","B","E"]
	@test ancestor(E) == tc["AB"]
	@test in(E, tc)
	@test in(E, children(tc["AB"]))
	@test branch_length(E) == 4
	@test_throws ErrorException graft!(tc, E, "CD") # E is not a root anymore

	# 2
	E = TreeNode(label = "E", tau = 5.)
	tc = copy(t)
	@test_throws ErrorException graft!(tc, E, tc["A"])
	graft!(tc, E, tc["A"], graft_on_leaf=true, tau = 1.)
	@test !isleaf(tc["A"])
	@test ancestor(E) == tc["A"]
	@test in(E, tc)
	@test in(E, children(tc["A"]))
	@test branch_length(E) == 1

	# 3
	E = node2tree(TreeNode(label = "E", tau = 5.))
	tc = copy(t)
	graft!(tc, E, "A", graft_on_leaf=true) # will copy E
	@test sort(map(label, children(tc["A"]))) == ["E"]
	@test isnothing(ancestor(E.root))
	@test check_tree(E)
	@test in("E", tc)
	@test_throws ErrorException graft!(tc, E, "CD")
end

@testset "Pruning" begin
	nwk = "((A:1,B:1)AB:2,(C:1,D:1)CD:2)R;"
	t = parse_newick_string(nwk)

	# 1
	tc = copy(t)
	r, a = prunesubtree!(tc, "AB")
	@test !in("AB", tc)
	@test !in("A", tc)
	@test isroot(a)
	@test isroot(r)
	@test check_tree(tc)
	@test sort(map(label, children(a))) == ["C", "D"]
	@test label(a) == "R"
	@test sort(map(label, children(r))) == ["A", "B"]

	# 2
	tc = copy(t)
	@test_throws ErrorException prunesubtree!(tc, "R")
	@test_throws KeyError prunesubtree!(tc, "X")
	@test_throws ErrorException prune!(tc, ["A", "C"])
	prunesubtree!(tc, ["A", "B"])
	@test_throws KeyError prunesubtree!(tc, "A")

	# 3
	tc = copy(t)
	tp = prune!(tc, ["A","B"]; remove_singletons = false)
	@test !in("AB", tc)
	@test !in("A", tc)
	@test in("AB", tp)
	@test in("A", tp)
	@test check_tree(tp) # tc has singletons so check_tree will fail
	@test sort(map(label, children(tc.root))) == ["CD"]

	# 4
	t = parse_newick_string("(A,(B,(C,(D))));")
	tp = prune!(t, ["B","D"], clade_only=false)
	@test length(leaves(t)) == 1
	@test length(leaves(tp)) == 3
	@test sort(map(label, leaves(tp))) == ["B","C","D"]
end

@testset "Deleting branches" begin
    root = TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_testnullbranches.nwk")
    TreeTools.delete_null_branches!(node2tree(root))
    @test root == TreeTools.read_newick("$(dirname(pathof(TreeTools)))/../test/prunegraft/tree_testnullbranches_.nwk")
end


nwk1 = "(A,(B,(C,D)))"
t1 = node2tree(TreeTools.parse_newick(nwk1))
