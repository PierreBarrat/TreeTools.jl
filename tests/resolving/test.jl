using Test
using TreeTools

println("##### Test resolving #####")

t1 = node2tree(TreeTools.parse_newick("(((A,B),C),D)"))
t2 = node2tree(TreeTools.parse_newick("(B,C,(A,D))"))
@testset "1" begin
	newsplits = resolve!(t1,t2)
	@test length(newsplits[1]) == 0
	@test length(newsplits[2]) == 0
end

t1 = read_tree("resolving/tree1.nwk")
t2 = read_tree("resolving/tree2.nwk")
@testset "2" begin
	newsplits = resolve!(t1,t2)
	@test newsplits[1].splits == [Split(Bool[1, 1, 0, 0, 0, 0, 0, 0, 0, 0])]
	X = sort([newsplits[2].leaves[x.dat] for x in newsplits[2].splits])
	@test X[1] == ["A1", "A2", "B", "C"]
	@test X[2] == ["D1", "D2"]
	@test X[3] == ["E", "F", "G", "H"]
end


t1 = node2tree(TreeTools.parse_newick("(A,B,C,D)"))
t2 = node2tree(TreeTools.parse_newick("(A,(B,C,D))"))
t3 = node2tree(TreeTools.parse_newick("(A,B,(C,D))"))

@testset "Node naming" begin
	ns12 = resolve!(t1,t2)
	ns13 = resolve!(t1,t3)
	@test isempty(ns12[2])
	@test isempty(ns12[2])
	@test haskey(t1.lnodes, "RESOLVED_1")
	@test haskey(t1.lnodes, "RESOLVED_2")
	@test !haskey(t1.lnodes, "RESOLVED_3")
end