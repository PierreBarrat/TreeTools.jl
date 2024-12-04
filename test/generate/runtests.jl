using TreeTools
using TreeTools.Generate
using Test

@testset verbose = true "Generate" begin
    @testset "Simple shapes" begin
        println("## Simple shapes")
        include("simple_shapes/test.jl")
    end

    @testset "Coalescent" begin
        println("## Coalescent")
        include("coalescent/test.jl")
    end

    @testset "Birth death" begin
        println("## Birth-death")
        include("birth_death/test.jl")
    end
end
