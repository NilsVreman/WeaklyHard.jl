export dominant_set

function _remove_equivalent(Lambda)
    #= Removes all but one of equivalent constraints =#

    Lambda_new = Set{Constraint}()
    for lambda_i in Lambda
        push!(Lambda_new, lambda_i)
        for lambda_j in Lambda
            if (lambda_i != lambda_j 
                    && lambda_j in Lambda_new 
                    && is_equivalent(lambda_i, lambda_j))

                delete!(Lambda_new, lambda_i)
                break
            end # if
        end # for
    end # for

    return Lambda_new
end # function

"""
    dominant_set(Lambda::Set{Constraint})

Calculates the dominant constraint set given a set of weakly-hard constraints, `Lambda`.

# Examples
```jldoctest
julia> dominant_set(Set([RowMissConstraint(1), 
                         AnyMissConstraint(3, 5), 
                         AnyMissConstraint(1, 7)]))
Set{Constraint} with 1 element:
  AnyMissConstraint(1, 7)
```
"""
function dominant_set(Lambda::Set{Constraint})::Set{Constraint}

    Lambda = _remove_equivalent(Lambda)

    # Return full set if there is only one constraint
    if length(Lambda) == 1
        return Lambda
    end

    # Add Constraints to a connectivity-graph
    dominance_graph = Dict(lambda => Set{Constraint}() for lambda in Lambda)
    for lambda_i in Lambda
        for lambda_j in Lambda
            if lambda_i != lambda_j
                # Add edge if lambda_i <= lambda_j
                if is_dominant(lambda_i, lambda_j) 
                    push!(dominance_graph[lambda_i], lambda_j)
                # Else, if 
                #   lambda_i </= lambda_j and lambda_j </= lambda_i, 
                # add undirected edge
                elseif !is_dominant(lambda_j, lambda_i) 
                    push!(dominance_graph[lambda_i], lambda_j)
                    push!(dominance_graph[lambda_j], lambda_i)
                end # if
            end # if
        end # for
    end # for

    # For all constraints
    for (lambda_i, doms) in dominance_graph
        # For all dominations of the constraint
        for lambda_j in doms
            # If lambda_j is in the dominance graph but it does not dominate
            # lambda_i, remove it (since lambda_i <= lambda_j).
            # NOTE: We do not have to remove it if it is not already in the graph.
            if lambda_j in keys(dominance_graph) && !(lambda_i in dominance_graph[lambda_j])
                delete!(dominance_graph, lambda_j)
            end # if
        end # for
    end # for

    # Return the dominant constraints
    return Set(keys(dominance_graph))
end # function
