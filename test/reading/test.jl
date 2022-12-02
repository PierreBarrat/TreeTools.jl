# println("##### reading #####")

using Test
using TreeTools

@testset "Basic" begin
	@test typeof(read_tree("$(dirname(pathof(TreeTools)))/../test/reading/trees.nwk")) <: Vector{<:Tree}
	@test typeof(read_tree("$(dirname(pathof(TreeTools)))/../test/reading/tree.nwk")) <: Tree
	@test isa(read_tree("$(dirname(pathof(TreeTools)))/../test/reading/tree.nwk"; node_data_type=MiscData), Tree{MiscData})

	@test read_tree("$(dirname(pathof(TreeTools)))/../test/reading/tree.nwk"; label="test_tree").label == "test_tree"
end
