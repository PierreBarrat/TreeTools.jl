# println("##### objects #####")

using TreeTools
using Test

@testset "Node relabel" begin
	nwk = "(A,(B,C));"
	t = parse_newick_string(nwk)
	label!(t, t["A"], "D")
	@test check_tree(t)
	@test !in("A", t)
	@test in("D", t)
	@test length(nodes(t)) == 5
	labels = map(label, POT(t))
	@test !in("A", labels)
	@test in("D", labels)
	@test sort(labels) == sort(collect(keys(t.lnodes)))

	@test_throws AssertionError label!(t, t["D"], "B")
	@test_throws AssertionError label!(t, "D", "B")
end

