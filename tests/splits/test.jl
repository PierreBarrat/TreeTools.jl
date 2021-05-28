using Test
using TreeTools

t = read_tree("splits/tree1.nwk")
S = SplitList(t)

@test [S.leaves[s.dat] for s in S] == [["A1", "A2"],
									["B1", "B2"],
									["C1", "C2"],
									["A1", "A2", "B1", "B2", "C1", "C2"],
									["A1", "A2", "B1", "B2", "C1", "C2", "D", "E"]]

s4 = S.splitmap["NODE_4"]
s5 = S.splitmap["NODE_5"]
s45 = TreeTools.joinsplits(s4,s5)
@testset "Splits" begin
	@test in(s4, S)
	@test in(s5, S)
	@test !in(s45, S)
	@test s45.dat == Bool[0, 0, 1, 1, 1, 1, 0, 0]
	@test !isnothing(findfirst(==(s5), S.splits))
	@test isnothing(findfirst(==(s45), S.splits))
end
