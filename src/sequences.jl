export random_sequence,
       all_sequences

#################
### Functions ###
#################

"""
    random_sequence(automaton::Automaton, N::Integer)

The function takes an arbitrary walk of length `N` in `automaton`. 
Returns a sequence that satisfy all weakly-hard constraints used to build the automaton.
"""
function random_sequence(automaton::Automaton{T}, N::S) where {T <: Integer, S <: Integer}

    if N < 8
        return _rand_seq(automaton.head, N, Int8(1))
    elseif N < 16
        return _rand_seq(automaton.head, N, Int16(1))
    elseif N < 32
        return _rand_seq(automaton.head, N, Int32(1))
    elseif N < 64
        return _rand_seq(automaton.head, N, Int64(1))
    else
        return _rand_seq(automaton.head, N, BigInt(1))
    end
end # function

"""
    all_sequences(automaton::Automaton, N::Integer)

The function returns a set containing all sequences of length `N` satisfying the constraints used to build the automaton.
In other words, the function generates the satisfaction set of length `N` sequences.

## Example
```jldoctest
julia> all_sequences(build_automaton(AnyHitConstraint(2, 3)), 5)
Set{Int8} with 9 elements:
  22
  13
  15
  29
  27
  31
  30
  14
  23
```
"""
function all_sequences(automaton::Automaton{T}, N::S) where {T <: Integer, S <: Integer}

    if N < 8
        return _recursive!(automaton.head, Set{Int8}(), N, Int8(0))
    elseif N < 16
        return _recursive!(automaton.head, Set{Int16}(), N, Int16(0))
    elseif N < 32
        return _recursive!(automaton.head, Set{Int32}(), N, Int32(0))
    elseif N < 64
        return _recursive!(automaton.head, Set{Int64}(), N, Int64(0))
    else
        return _recursive!(automaton.head, Set{BigInt}(), N, BigInt(0))
    end
end # function

#####################
### Aux functions ###
#####################

function _rand_seq(vertex::WordVertex{T}, N::S, seq::R) where {T <: Integer, S <: Integer, R}
    # Random walk
    for _ in 1:N-1
        seq <<= R(1)
        c::Symbol = _rand_neighbour!(vertex)
        vertex = getfield(vertex, c)
        seq |= (c === :miss) ? R(0) : R(1)
    end # for
    return seq
end # function

function _rand_neighbour!(vertex::WordVertex{T})::Symbol where {T <: Integer}
    #= Picks a random neighbour =#
    if _childexists(vertex, :miss)
        return rand([:miss, :hit])
    else
        return :hit
    end
end # function



function _recursive!(vertex::WordVertex{T},
                     seq_set::Set{R},
                     N::S,
                     seq::R) where {T <: Integer, R <: Integer, S <: Integer}
    _recursive_sequence!(vertex, seq_set, N, seq)
    return seq_set
end # function
function _recursive_sequence!(vertex::WordVertex{T},
                              seq_set::Set{R},
                              N::S,
                              seq::R) where {T <: Integer, R <: Integer, S <: Integer}
    if N == 0 # base case
        push!(seq_set, seq)
    else
        if _childexists(vertex, :miss)
            _recursive_sequence!(vertex.miss, seq_set, N-S(1), seq << R(1))
        end
        _recursive_sequence!(vertex.hit, seq_set, N-S(1), (seq << R(1)) | R(1))
    end
end # function
