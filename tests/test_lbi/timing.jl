using TreeTools
using Profile, ProfileView

t1 = read_tree("../tree1.nwk", DataType=LBIData);

function time_lbi(t)
	# lbi!(t)
	@time lbi!(t, 1.)
end

function profile_lbi(t; n = 1000)
	Profile.clear()
	@profile for i in 1:n
		lbi!(t, 1.)
	end
end

mutable struct mystruct
	x::Union{Missing,Float64}
end

function test()
	@time a = mystruct(1.)
	@time b = mystruct(missing)
	@time a.x += b.x
end