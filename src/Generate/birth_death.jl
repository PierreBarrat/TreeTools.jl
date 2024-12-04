"""
    birth_death(n::Integer, λ::Real, μ::Real; active=false, warn_incomplete=true)

Simulate a birth death process with rates `λ` (birth) and `μ` (death).
Stop when there are `n` lineages.
Return the a `Tree` and a boolean indicating completion of the process: it is `false`
if all lineages died before reaching the target `n`.


Keyword argument `active` (default: `false`) controls whether only active lineages (*i.e.* non dead)
count towards completion.
If `active=false`, the number of leaves of output tree is `n` if the process completed.
If `active=true`, it is larger than `n`.
"""
function birth_death(n::Integer, λ::Real, μ::Real; active=false, warn_incomplete=true)
    @argcheck n > 0 "`n` must be positive. Instead $n"
    @argcheck (λ >= 0) && (μ >= 0)
    """Birth and death rate must be positive. Instead λ=$λ, μ=$μ"""
    # Initialize
    tree = Tree()
    label!(tree, root(tree), "root")
    branch_length!(root(tree), 0.) # makes sense in the B-D - set it to missing at the end
    active_lineages = [root(tree)]

    # Utility to count the lineages that count towards the goal `n`
    number_of_lineages(tree, active_lineages, active) = if active
        length(active_lineages)
    else
        length(leaves(tree))
    end

    # Running the process
    while number_of_lineages(tree, active_lineages, active) < n
        nlin = length(active_lineages) # these count for the birth/death rate
        nlin == 0 && break # everyone died
        @debug "There are $(nlin) active lineages"
        event, time = choose_birth_death_event(nlin, λ, μ)
        @debug "Event $event after time $time"
        do_birth_death_event!(tree, active_lineages, event, time)
        @debug "There are $(nlin) active lineages"
    end

    # last event - for the last cherry to not have zero branch length
    # doing it this way makes this exactly equivalent to the yule coalescent
    event, time = choose_birth_death_event(nlin, λ, μ)
    foreach(n -> n.tau += time, active_lineages)

    # labelling
    branch_length!(root(tree), missing)
    # label!(tree, root(tree), "root")
    for (i, node) in enumerate(traversal(tree; internals=false))
        label!(tree, node, "$i")
    end

    # Check if process succeeded
    nlin = number_of_lineages(tree, active_lineages, active)
    @assert nlin <= n "More lineages than expected: impossible!"
    completed = (nlin == n)
    if warn_incomplete && !completed
        @warn """
        Birth death process did not go to completion of $(n) lineages.
        Final number of lineages is $(nlin).
        """
    end

    return tree, completed
end

function do_birth_death_event!(tree, active_lineages, event, time)
    # update the time of all lineages
    foreach(n -> n.tau += time, active_lineages)
    if event == :birth
        # Pick an active lineage at random and graft two leaves on it
        # Remove it from active lineages
        # add the two leaves to active lineages
        idx = rand(1:length(active_lineages))
        lineage = active_lineages[idx]
        @assert isleaf(lineage) "`active_lineages` should always be leaves. Algorithm issue"

        l1, l2 = TreeNode(tau=0.), TreeNode(tau=0.)
        graft!(tree, l1, lineage; graft_on_leaf=true)
        graft!(tree, l2, lineage; graft_on_leaf=true)

        deleteat!(active_lineages, idx)
        push!(active_lineages, l1, l2)
    elseif event == :death
        # Pick an active lineages and remove it from active lineages
        deleteat!(active_lineages, rand(1:length(active_lineages)))
    else
        throw(ArgumentError("Expect event to be `:birth` or `:death`. Instead $event"))
    end
    return nothing
end

function choose_birth_death_event(n, λ, μ)
    ν = (λ + μ) * n
    time = rand(Exponential(1/ν))
    event = rand() > λ / (λ + μ) ? :death : :birth
    return event, time
end
