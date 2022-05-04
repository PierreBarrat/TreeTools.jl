using Test
using TreeTools

println("##### iterators #####")

begin
	nwk = "(((A1:1,A2:1,B:1,C:1)i_2:0.5,(D1:0,D2:0)i_3:1.5)i_1:1,(E:1.5,(F:1.0,(G:0.,H:0.)i_6:0.5)i_5:1)i_4:1)i_r"
	tnodes = sort(["A1", "A2", "B", "C", "i_2", "D1", "D2", "i_3", "i_1", "E", "F", "G", "H", "i_6", "i_5", "i_4", "i_r"])
	tleaves = sort(["A1", "A2", "B", "C", "D1", "D2", "E", "F", "G", "H"])

	@testset "1" begin
		t = node2tree(TreeTools.parse_newick(nwk))
		@test sort([x.label for x in POT(t)]) == tnodes
		@test sort([x.label for x in POTleaves(t)]) == tleaves
	end

	@testset "in" begin
		for n in nodes(tree)
			@test in(n, tree)
			@test in(n.label, tree)
			if !n.isleaf
				@test !in(n, tree; exclude_internals=true)
			end
		end
	end

	@testset "indexing in tree" begin
		for n in nodes(tree)
			@test tree[n.label] == tree.lnodes[n.label]
		end
		@test_throws KeyError tree["some_random_string"]
	end
end
