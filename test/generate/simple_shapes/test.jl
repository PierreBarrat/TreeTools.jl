using Test
using TreeTools

using Chain
using TreeTools.Generate

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

    @test_throws ArgumentError star_tree(3, [1, 2])
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

@testset "ladder tree" begin
    @test_throws ArgumentError ladder_tree(0)
    @test ladder_tree(1) isa Tree

    n = 5
    T = 2.0
    tree = ladder_tree(n, T)
    τ = T / (n - 1)
    @test length(leaves(tree)) == n
    @test length(nodes(tree)) == 2n - 1
    @test all(node -> length(children(node)) == 2, internals(tree))
    @test height(tree) ≈ T
    @test height(tree; topological=true) == n - 1
    # leaf `k` sits at depth `n - k + 1` (leaf 1 is the deepest, along with leaf 2)
    @test branch_length(tree["$n"]) ≈ T
    @test branch_length(tree["1"]) ≈ τ
    @test branch_length(tree["2"]) ≈ τ
    @test branch_length(tree["3"]) ≈ 2τ

    # missing total height
    @test all(ismissing ∘ branch_length, leaves(ladder_tree(4)))

    # large trees must not overflow the stack
    n = 20_000
    tree = ladder_tree(n, 1.0)
    @test length(leaves(tree)) == n
    @test length(nodes(tree)) == 2n - 1
end
