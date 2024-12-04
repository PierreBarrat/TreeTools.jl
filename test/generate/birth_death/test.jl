using Distributions
using Random
using Test
using TreeTools
using TreeTools.Generate

# Test suite for `birth_death`
@testset "birth_death tests" begin
    # Test 1: Basic functionality
    @testset "Basic functionality" begin
        n = 5
        λ = 0.5
        μ = 0.3
        tree, completed = birth_death(n, λ, μ; active=false, warn_incomplete=false)
        @test tree isa Tree
        @test completed isa Bool
    end

    # Test 2: Invalid input for `n`
    @testset "Invalid input handling" begin
        @test_throws ArgumentError birth_death(-1, 0.5, 0.3)
        @test_throws ArgumentError birth_death(0, 0.5, 0.3)
        @test_throws ArgumentError birth_death(0, -1, 0.3)
    end

    # Test 3: Edge case where all lineages die before reaching target `n`
    @testset "All lineages die before reaching target" begin
        n = 2
        λ = 0.
        μ = 1.0
        tree, completed = birth_death(n, λ, μ; active=false, warn_incomplete=false)
        @test !completed
    end

    @testset "All lineages count towards completion" begin
        n = 3
        λ = 0.7
        μ = 0.2
        for _ in 1:10
            tree, completed = birth_death(n, λ, μ; active=false, warn_incomplete=false)
            @test !completed || length(leaves(tree)) == n
        end
    end

    # Test 5: Edge case of no death
    @testset "No death" begin
        n = 50
        λ = 1.0
        μ = 0.
        for _ in 1:10
            tree, completed = birth_death(n, λ, μ; active=true, warn_incomplete=false)
            @test completed # should always complete
            @test length(leaves(tree)) == n # even if active=true, all lineages remain active
        end
    end
end
