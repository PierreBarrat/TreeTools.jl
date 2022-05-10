using Test
using TreeTools

@testset "Basic" begin
	@test typeof(read_tree("trees.nwk")) <: Vector{<:Tree}
	@test typeof(read_tree("tree.nwk")) <: Tree
end
