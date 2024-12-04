```@meta
DocTestSetup = quote
	using TreeTools
end
```

# Generating trees

`TreeTools` has three ways to generate trees: 
- using a birth-death process (*i.e.* forward simulation);
- using a coalescent process (*i.e.* backward simulation);
- using a collection of pre-defined simple shapes. 
All three methods are accessible through the `TreeTools.Generate` submodule. 
For now, this is not exported: most functions below need to be prefaced by an explicit `TreeTools.Generate`. 

## Birth-death process

This is rather straightforward: 
```@repl
using TreeTools # hide
begin
	n = 25 # number of lineages to reach for completion
	b = 1 # birth rate
	d = 0.1 # death rate
end;
tree, completed = TreeTools.Generate.birth_death(n, b, d)
length(leaves(tree)) == n || !completed
```
The second output argument `completed` is a boolean indicating whether the process reached the target `n` lineages.
If the death rate is non-zero, it is possible that all lineages die before completion. 

The implemented process starts with one lineage (the root). 
Then, if there are ``n`` lineages in the tree: 
- with rate ``b\cdot n``, trigger a birth event: pick a lineage at random and split it in two;
- with rate ``d\cdot n``, trigger a death event: stop the lineage and place a leaf at its end;
- if `n` reaches the target value for completion or if all lineages are dead, stop the process by placing a leaf at the end of each lineage.

## Coalescent process

There are two coalescent models implemented. 
- The classical Kingman's process, with a rate of coalescence ``\nu = n(n-1)/N`` for ``n`` lineages, where ``N`` is a parameter (the population size).
- The Yule process, with a rate of coalescence ``\nu = b\cdot n`` for ``n`` lineages, where ``b`` can be interpreted as a birth rate. This is equivalent to a birth only forward process. 

Generating a coalescent tree is a two-step process: first construct a `Coalescent` object, then give it to the function `genealogy`. 
```@repl coalescent
using TreeTools # hide
kingman = TreeTools.Generate.KingmanCoalescent(n=25, N=10_000)
yule = TreeTools.Generate.YuleCoalescent(n=5, b=1)
tree = TreeTools.Generate.genealogy(kingman)
distance(root(tree), first(leaves(tree))) # ~2N on average
tree = TreeTools.Generate.genealogy(yule)
distance(root(tree), first(leaves(tree))) # ~b log(n) on average
```

It is possible to create custom coalescent. 
Below, we create a backward process with multiple mergers, with the following properties: 
- the rate of merging is ``\rho``, independent of the number of lineages ``n``;
- when a merge occurs, an average fraction ``\beta`` of the ``n`` lineages is involved (sampled using a binomial). 
First, we define the corresponding coalescent type. 
Importantly, the field `n` must be present in the `struct`, and is interpreted as the number of remaining lineages. 

```@repl customcoa
using TreeTools # hide
@kwdef mutable struct MultipleMerger <: TreeTools.Generate.Coalescent
    n::Int # number of lineages
    β::Float64 # parameters 
    ρ::Float64
end
```

Now, we need to define the `choose_event` function that samples a merge event from this process.
The return value should be a tuple `k, t` with `k` being the number of lineages involved in the merge and `t` the time to the event. 
```@repl customcoa
using Distributions
import TreeTools.Generate.choose_event
function choose_event(C::MultipleMerger)
    C.n <= 1 &&  throw(ArgumentError("Cannot choose coalescence event for $(C.n) lineage."))
    t = 0.
    merger = 0
    coin = Binomial(C.n, C.β) # this is from Distributions, 
    while merger < 2
        t += rand(Exponential(1/C.ρ))
        merger = rand(coin)
    end
    return merger, t
end
```

Now we can sample from this
```@repl customcoa
mm = MultipleMerger(n=15, β=.25, ρ=1)
tree = TreeTools.Generate.genealogy(mm)
using StatsBase
map(n -> length(children(n)), internals(tree)) |> countmap # if we're not unlucky, there should be some multiple mergers in here! 
```

## Basic shapes

There are three at the moment, with self explanatory names: 
```@repl 
using TreeTools # hide
star = TreeTools.Generate.star_tree(4, 1.)
ladder = TreeTools.Generate.ladder_tree(4, 1.)
balanced = TreeTools.Generate.balanced_binary_tree(4, 1.)
```
The docstrings give a bit more detail. 