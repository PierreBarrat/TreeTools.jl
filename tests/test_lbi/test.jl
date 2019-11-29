# t1 = read_tree("../tree1.nwk", DataType=LBIData);
# set_live_nodes!(t1, set_leaves=true)
# lbi!(t1, 1, normalize=true)
# println("ALL NODES ALIVE")
# [(x.label, x.data.alive, x.data.lbi) for x in values(t1.nodes)]
# t1.lnodes["C"].data.alive = false; t1.lnodes["D"].data.alive = false; set_live_nodes!(t1, set_leaves=false);
# lbi!(t1, 1, normalize=true)
# println("C and D dead")
# [(x.label, x.data.alive, x.data.lbi) for x in values(t1.nodes)]

global τ = 0.5
@testset "LBI - Basic tree" begin
	t0 = read_tree("tree0.nwk", DataType=LBIData)
	lbi!(t0, τ)
	@test isapprox(t0.lnodes["A"].data.lbi, τ * (2 - exp(-t0.lnodes["B"].data.tau/τ) - exp(-t0.lnodes["C"].data.tau/τ)), rtol = .01)
	@test isapprox(t0.lnodes["B"].data.lbi, τ * (1 - exp(-(t0.lnodes["B"].data.tau + t0.lnodes["C"].data.tau)/τ)), rtol = .01)
end

@testset "LBI - Bigger tree" begin
	t1 = read_tree("tree1.nwk", DataType=LBIData)
	lbi!(t1, τ)
	e = exp(-t1.lnodes["A"].data.tau/τ)
	@test isapprox(t1.lnodes["ABCD"].data.lbi, 2τ*((1-e) + 2e*(1-e)), rtol=0.01 )
	t1.lnodes["A"].data.alive = false
	@test isapprox(t1.lnodes["ABCD"].data.lbi, 2τ*((1-e) + 3/2*e*(1-e)), rtol=0.01 )
	@test isapprox(t1.lnodes["CD"].data.lbi, τ*(2(1-e) + 1-e^3), rtol=0.01)
end