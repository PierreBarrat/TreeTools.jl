using Test
using TreeTools

using Chain

@testset "star tree" begin
    n = 16
    times = rand(n)
    tree = star_tree(n, times)
    @test length(nodes(tree)) == n+1
    for node in leaves(tree)
        @test branch_length(node) == times[parse(Int, label(node))]
    end

    tree = star_tree(n)
    for node in leaves(tree)
        @test ismissing(branch_length(node))
    end

    @test_throws AssertionError star_tree(3, [1,2])
end
