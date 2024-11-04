using Test
using TreeTools

using Chain

@testset "star tree" begin
    n = 16
    times = rand(n)
    tree = star_tree(n, times)
    @test length(nodes(tree)) == n + 1
    for node in leaves(tree)
        @test branch_length(node) == times[parse(Int, label(node))]
    end

    tree = star_tree(n)
    for node in leaves(tree)
        @test ismissing(branch_length(node))
    end

    @test_throws AssertionError star_tree(3, [1, 2])
end

@testset "balanced binary" begin
    @test_throws ErrorException balanced_binary_tree(3)
    @test_throws ErrorException balanced_binary_tree(0)

    n = 16
    τ = 2.5
    tree = balanced_binary_tree(n, τ)
    @test length(leaves(tree)) == n
    @test allequal(branch_length, nodes(tree; skiproot=true)) # comparing floats...
    @test all(leaves(tree)) do leaf
        !isnothing(tryparse(Int, label(leaf))) # leaves have labels like "1", "2", etc...
    end
    @test all(node -> length(children(node)) == 2, internals(tree))

    @test balanced_binary_tree(1) isa Tree
end
