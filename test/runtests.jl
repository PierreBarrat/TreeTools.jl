using TreeTools

@testset verbose=true "TreeTools" begin

	include("$(dirname(pathof(TreeTools)))/../test/reading/test.jl")
	include("$(dirname(pathof(TreeTools)))/../test/objects/test.jl")
	include("$(dirname(pathof(TreeTools)))/../test/methods/test.jl")

	@testset "Prune/Graft" begin
		println("## Prune/Graft")
		include("prunegraft/test.jl")
	end

	include("$(dirname(pathof(TreeTools)))/../test/iterators/test.jl")
	include("$(dirname(pathof(TreeTools)))/../test/splits/test.jl")

end

