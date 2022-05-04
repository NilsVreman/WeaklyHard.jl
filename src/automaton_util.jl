export vertices,
    transitions,
    minimize_automaton!

#################
### Overloads ###
#################

#= WordVertex - Returns whether the child s exists for n =#
_childexists(n::WordVertex{T}, s::Symbol) where {T <: Integer}  = !isnothing(getfield(n, s))

#= Automaton - Overloads of Base functions =#
Base.getindex(g::Automaton{T}, w::T) where {T <: Integer}                       = g.data[w]
Base.setindex!(g::Automaton{T}, v::WordVertex{T}, w::T) where {T <: Integer}    = (g.data[w] = v)
Base.length(g::Automaton{T}) where {T <: Integer}                               = length(g.data)
Base.haskey(g::Automaton{T}, w::T) where {T <: Integer}                         = haskey(g.data, w)

######################
### Util Functions ###
######################

"""
    vertices(automaton::Automaton)

Returns all the vertices in `automaton`.
"""
function vertices(automaton::Automaton{T}) where {T <: Integer}
    return values(automaton.data)
end # function

"""
    transitions(automaton::Automaton)

Returns all the transitions in `automaton` in the form of a set of pairs where each pair consists of `(v1, v2, c12)`, i.e., the tail of the transition `v1`, the head of the transition `v2`, and the label of the transition `c12`.
"""
function transitions(automaton::Automaton{T}) where {T <: Integer}

    trans = Set{Tuple{T, T, UInt8}}();
    sizehint!(trans, 2*length(vertices(automaton)))

    for vertex in vertices(automaton)
        push!(trans, (vertex.w, vertex.hit.w, Hit))
        if _childexists(vertex, :miss)
            push!(trans, (vertex.w, vertex.miss.w, Miss))
        end # if
    end # for

    return trans
end # function

function _vertices_equivalent(v1::WordVertex{T}, v2::WordVertex{T}) where {T <: Integer} 
    if v1 === v2 # If they are the same vertex
        return false
    end

    if _childexists(v1, :miss) && _childexists(v2, :miss)
        return v1.miss.w == v2.miss.w && v1.hit.w == v2.hit.w
    elseif !_childexists(v1, :miss) && !_childexists(v2, :miss)
        return v1.hit.w == v2.hit.w
    else
        return false
    end #if
end # function

"""
    minimize_automaton!(automaton::Automaton)

Minimises the automaton representation of a set of weakly-hard constraints. 
"""
function minimize_automaton!(automaton::Automaton{T}) where {T <: Integer}
    changed = true
    while changed
        changed = false

        for v1 in vertices(automaton)
            v1_identical = Vector{WordVertex{T}}()
            for v2 in vertices(automaton)
                if _vertices_equivalent(v1, v2)
                    changed = true
                    push!(v1_identical, v2)
                end
            end # for

            if !isempty(v1_identical)
                push!(v1_identical, v1)
                # find shortest word to replace v1_identical with
                v1_new = reduce(v1_identical) do x, y
                (x.w < y.w) ? x : y end
                for v3 in vertices(automaton)
                    if v3 in v1_identical && !(v3 === v1_new)
                        delete!(automaton.data, v3.w)
                    else 
                        if _childexists(v3, :miss) && v3.miss in v1_identical
                            v3.miss = v1_new
                        end
                        if v3.hit in v1_identical
                            v3.hit = v1_new
                        end
                    end # if
                end # for
            end # if
        end # for
    end # while
    return automaton
end # function

###########################
### Auxiliary Functions ###
###########################

#= Find minimal sized Integer to use for automaton construction =#
function _word_type(Lambda::Set{T}, k::S) where {T <: Constraint, S <: Integer}
    n = 0
    for lambda in Lambda
        if typeof(lambda) == RowHitConstraint && lambda.x > n
            n = lambda.x
        end # if
    end # for

    if k + 2*n < 64 - 2
        return Int64
    else
        return BigInt
    end # if
end # function

_word_type(lambda::T, k::S) where {T <: Constraint, S <: Integer} = _word_type(Set{T}([lambda]), k)

#= Find minimal size of automaton (specifically used by sizehint for the dictionary in the automaton) =#
_minimal_size(lambda::AnyHitConstraint)  = binomial(lambda.k, lambda.x)
_minimal_size(lambda::AnyMissConstraint) = binomial(lambda.k, lambda.k - lambda.x)
_minimal_size(lambda::RowMissConstraint) = lambda.x + 1
function _minimal_size(lambda::RowHitConstraint)
    if lambda.x > lambda.k
        return 0
    elseif lambda.k < 2*lambda.x
        return 1
    elseif lambda.k == 2*lambda.x
        return lambda.x + 1
    elseif lambda.k == 2*lambda.x + 1
        return lambda.x + 2
    elseif lambda.k < 3*lambda.x
        return 2*_minimal_size(RowHitConstraint(lambda.x, lambda.k - 1)) - _minimal_size(RowHitConstraint(lambda.x, lambda.k - 2)) + 1
    else
        return _minimal_size(RowHitConstraint(lambda.x, lambda.k - 1)) + lambda.x
    end # if 
end # function
