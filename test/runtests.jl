using TreeTools
using Test

@testset verbose=true "TreeTools" begin
	@testset "Reading" begin
		println("## Reading")
		include("$(dirname(pathof(TreeTools)))/../test/reading/test.jl")
	end

	@testset "Objects" begin
		println("## Objects")
		include("$(dirname(pathof(TreeTools)))/../test/objects/test.jl")
	end

	@testset "Methods" begin
		println("## Methods")
		include("$(dirname(pathof(TreeTools)))/../test/methods/test.jl")
	end

	@testset "Prune/Graft" begin
		println("## Prune/Graft")
		include("prunegraft/test.jl")
	end

	@testset "Iterators" begin
		println("## Iterators")
		include("$(dirname(pathof(TreeTools)))/../test/iterators/test.jl")
	end

	@testset "Splits" begin
		println("## Splits")
		include("$(dirname(pathof(TreeTools)))/../test/splits/test.jl")
	end
end

