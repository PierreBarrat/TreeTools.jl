using Test
using TreeTools

global τ = 0.5
@testset "LBI - Basic tree" begin
	t0 = read_tree("tree0.nwk", NodeDataType=LBIData)
	lbi!(t0, τ)
	@test isapprox(t0.lnodes["A"].data.lbi, τ * (2 - exp(-t0.lnodes["B"].data.tau/τ) - exp(-t0.lnodes["C"].data.tau/τ)), rtol = .1)
	@test isapprox(t0.lnodes["B"].data.lbi, τ * (1 - exp(-(t0.lnodes["B"].data.tau + t0.lnodes["C"].data.tau)/τ)), rtol = .1)
end

@testset "LBI - Bigger tree" begin
	t1 = read_tree("tree1.nwk", NodeDataType=LBIData)
	lbi!(t1, τ)
	e = exp(-t1.lnodes["A"].data.tau/τ)
	@test isapprox(t1.lnodes["ABCD"].data.lbi, 2τ*((1-e) + 2e*(1-e)), rtol=0.1 )
	t1.lnodes["A"].data.alive = false
	@test isapprox(t1.lnodes["ABCD"].data.lbi, 2τ*((1-e) + 3/2*e*(1-e)), rtol=0.1 )
	@test isapprox(t1.lnodes["CD"].data.lbi, τ*(2(1-e) + 1-e^3), rtol=0.1)
end