export random_sequence,
       all_sequences

#################
### Functions ###
#################

"""
    random_sequence(automaton::Automaton, N::Integer)

The function takes an arbitrary walk of length N in automaton. 
Returns a sequence that satisfy all weakly-hard constraints used to build the
automaton.
"""
function random_sequence(automaton::Automaton{T}, N::S) where {T <: Integer, S <: Integer}

    # Initialise start vertex, character vector, and sequence
    IntType = BigInt
    if N < 8
        IntType = Int8
    elseif N < 16
        IntType = Int16
    elseif N < 32
        IntType = Int32
    elseif N < 64
        IntType = Int64
    end
    seq             = IntType(0)
    cmp_word        = IntType(1)
    current_vertex  = automaton.head

    # Random walk
    for _ in 1:N
        seq <<= T(1)
        seq |= current_vertex.w & cmp_word
        current_vertex = _rand_neighbour(current_vertex)
    end # for

    return seq
end # function

"""
    all_sequences(automaton::Automaton, N::Integer)

The function returns a set containing all sequences of length N satisfying the
constraints used to build the automaton. In other words, the function generates
the satisfaction set of length N sequences.
"""
function all_sequences(automaton::Automaton{T}, N::S) where {T <: Integer, S <: Integer}
    # @description
    #   The function returns a set containing all sequences of length N
    #   satisfying the constraints used to build the automaton.
    # @param 
    #   automaton::Automaton:     The weakly-hard automaton
    #   N::Integer:               The length of the sequence to be generated
    # @returns 
    #   Set{<: Integer}: The resulting set of words (of length N) satisfying the
    #   weakly-hard automaton constraints.

    IntType = BigInt
    if N < 8
        IntType = Int8
    elseif N < 16
        IntType = Int16
    elseif N < 32
        IntType = Int32
    elseif N < 64
        IntType = Int64
    end

    seq_set = Set{IntType}()
    _recursive_sequence!(automaton.head, seq_set, N, IntType(0))
    return seq_set
end # function

#####################
### Aux functions ###
#####################

function _rand_neighbour(vertex::WordVertex{T}) where {T <: Integer}
    #= Picks a random neighbour =#
    if _childexists(vertex, :miss)
        return getfield(vertex, rand([:miss, :hit]))
    else
        return vertex.hit
    end
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
