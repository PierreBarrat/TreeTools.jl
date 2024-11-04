using TreeTools
using Test

@testset verbose = true "TreeTools" begin
    @testset "IO" begin
        println("## IO")
        include("$(dirname(pathof(TreeTools)))/../test/IO/test.jl")
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

    @testset "Simple shapes" begin
        println("## Shapes")
        include("$(dirname(pathof(TreeTools)))/../test/simple_shapes/test.jl")
    end
end
