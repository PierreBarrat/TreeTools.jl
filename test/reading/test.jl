println("##### reading #####")

using Test
using TreeTools

@testset "Basic" begin
	@test typeof(read_tree("$(dirname(pathof(TreeTools)))/../test/reading/trees.nwk")) <: Vector{<:Tree}
	@test typeof(read_tree("$(dirname(pathof(TreeTools)))/../test/reading/tree.nwk")) <: Tree
end
