#========================#
######### Models #########
#========================#

abstract type Coalescent end


@kwdef mutable struct KingmanCoalescent <: Coalescent
    n::Int = 2
    N::Float64 = 1
end
function choose_event(C::KingmanCoalescent)
    @assert C.n > 1 "Cannot choose coalescence event for one lineage." C
    τ = rand(Exponential(2*C.N/C.n/(C.n-1)))
    return 2, τ
end

"""
    mutable struct YuleCoalescent

```julia
n::Int = 2
b::Float64 = 1 # birth rate
```
Rate of coalescence `(n-1)b`.
The expected height of the tree is (I think) `~log(n)/b`
"""
@kwdef mutable struct YuleCoalescent <: Coalescent
    n::Int = 2
    b::Float64 = 1 # birth rate
end
function choose_event(Y::YuleCoalescent)
    @assert Y.n > 1 "Cannot choose coalescence event for one lineage." Y
    τ = rand(Exponential(1/(Y.n-1)/Y.b))
    return 2, τ
end

"""
    EFCoalescent

```
mutable struct EFCoalescent
    n::Int
    β::Float64
    ρ::Float64
end
```
"""
mutable struct EFCoalescent <: Coalescent
    n::Int
    β::Float64
    ρ::Float64
end
Ne(C::EFCoalescent) = 1/C.ρ/C.β/C.β
function choose_event(C::EFCoalescent)
    @assert C.n > 1 "Cannot choose coalescence event for one lineage." C
    τ = 0.
    merger = 0
    coin = Binomial(C.n, C.β)
    while merger < 2
        τ += rand(Exponential(1/C.ρ))
        merger = rand(coin)
    end
    return merger, τ
end

"""
    mutable struct SEFCoalescent

Stochastic EF coalescent. At each step, β is chosen from a distribution.

## Fields
```
    n::Int
    β::Distribution
    ρ::Float64
```
"""
mutable struct SEFCoalescent{T<:UnivariateDistribution} <: Coalescent
    n::Int
    β::T
    ρ::Float64
end
function choose_event(C::SEFCoalescent)
    @assert C.n > 1 "Cannot choose coalescence event for one lineage." C
    τ = 0.
    merger = 0
    while merger < 2
        τ += rand(Exponential(1/C.ρ))
        βval = rand(C.β)
        coin = Binomial(C.n, βval)
        merger = rand(coin)
        @debug "`SEFCoalescent`: using β=$(βval)"
    end
    return merger, τ
end


#================================================#
################# Main functions #################
#================================================#
"""
    genealogy(C::Coalescent; coalescence_times = false)

Return a tree sampled from the coalescent `C`. If `coalescence_times`, also return the
times `Tn` during which `n` lineages are present, in the form of a dictionary `n => Tn`.

## Examples
For the Kingman coalescent with population size `N` and `n=100` lineages:
```
tree = genealogy(KingmanCoalescent(100, N))
```
"""
function genealogy(C::Coalescent; coalescence_times = false)
    # Leaves
    nodes = [TreeNode(label="$i") for i in 1:C.n]
    reset_id()
    r, T = genealogy!(nodes, deepcopy(C))
    if coalescence_times
        return node2tree(r), T
    else
        return node2tree(r)
    end
end

function genealogy!(nodes::Vector{<:TreeNode}, C::Coalescent, T = Dict())
    @debug "$(C.n) lineages remaining"
    merger_size, τ = choose_event(C) # number of nodes to be coalesced and time to event
    @debug "Coalescence of $(merger_size) nodes at time $τ"
    T[C.n] = τ
    merged_ids = sample(eachindex(nodes), merger_size, replace=false, ordered=true)
    new_nodes = merge!(nodes, merged_ids, τ)
    C.n += -merger_size + 1 # k lineages merge into one
    @assert C.n == length(nodes) "Inconsistent number of remaining lineages: \
        $(C.n) vs. $(length(nodes))"

    if C.n == 1
        return nodes[1], T
    else
        return genealogy!(nodes, C, T)
    end
end

"""
    merge!(nodes, ids, τ)

Merge `nodes[ids]` into one common ancestor, with branch length `τ`, and remove them from
  `nodes`. The new ancestor is pushed at the end of `nodes`.
"""
function merge!(nodes, ids, τ)
    # Updating branch length
    for n in nodes
        n.tau = ismissing(n.tau) ? τ : n.tau + τ
    end
    # Merging nodes
    r = TreeNode(label="internal_$(get_id())")
    for n in nodes[ids]
        TreeTools.graftnode!(r, n)
    end
    deleteat!(nodes, ids)
    push!(nodes, r)
    return nothing
end

coalescence_times(C::Coalescent) = coalescence_times!(deepcopy(C), Dict{Int, Float64}())
function coalescence_times!(C::Coalescent, T::Dict)
    merger_size, τ = choose_event(C) # number of nodes to be coalesced and time to event
    T[C.n] = τ
    C.n += -merger_size + 1

    if C.n == 1
        return T
    else
        return coalescence_times!(C, T)
    end
end

tree_height(C::Coalescent) = tree_height!(deepcopy(C), 0)
function tree_height!(C::Coalescent, H)
    merger_size, τ = choose_event(C) # number of nodes to be coalesced and time to event
    H += τ
    C.n += -merger_size + 1
    if C.n == 1
        return H
    else
        return tree_height!(C, H)
    end
end

let i = 0
    global get_id() = (i+=1)
    global reset_id() = (i=0)
end

