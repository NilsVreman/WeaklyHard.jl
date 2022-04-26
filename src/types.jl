export AbstractAutomaton, 
    Automaton,
    WordVertex,
    Constraint,
    RowHitConstraint,
    RowMissConstraint,
    AnyHitConstraint,
    AnyMissConstraint,
    Hit, H,
    Miss, M,
    AnyChar, X

################
### Alphabet ###
################

const Miss      = UInt8(0)
const Hit       = UInt8(1)
const AnyChar   = UInt8(2)
const H         = Hit
const M         = Miss
const X         = AnyChar

##################
### WordVertex ###
##################

"""
A struct keep track of the current node and its direct children (if some exist).
"""
mutable struct WordVertex{T <: Integer}
    w::T
    miss::Union{Nothing, WordVertex{T}}
    hit::Union{Nothing, WordVertex{T}}

    #= WordVertex constructors =#
    WordVertex{T}(w) where {T <: Integer}             = new(w, nothing, nothing)
    WordVertex{T}(w, miss, hit) where {T <: Integer}  = new(w, miss, hit)
end # struct

#################
### Automaton ###
#################

#= Abstract representation of an automaton type =#
abstract type AbstractAutomaton end

"""
    Automaton()

Automaton struct containing a dict to represent the vertices (including head) and transitions of the automaton.

* Key     = Word (represented by integer). 
* Value   = WordVertex (containing current vertex and its direct children vertices)
"""
struct Automaton{T <: Integer} <: AbstractAutomaton
    head::Union{Nothing, WordVertex{T}}
    data::Dict{T, WordVertex{T}}

    #= Automaton Constructor =#
    Automaton{T}(head) where {T <: Integer} = new(head, Dict{T, WordVertex{T}}())
    Automaton{T}() where {T <: Integer} = new(nothing, Dict{T, WordVertex{T}}())
end # struct

###################
### Constraints ###
###################

#= Abstract representation of a constraint type =#
abstract type Constraint end

#= Data representation for individual constraints =#
struct ConstraintData
    x::Int64
    k::Int64
    ConstraintData(x, k) = (x < 0 || x > k || k < 1) ? error("Invalid input") : new(x, k)
end

struct RowHitConstraint <: Constraint
    data::ConstraintData
end

struct RowMissConstraint <: Constraint
    data::ConstraintData
end

struct AnyHitConstraint <: Constraint
    data::ConstraintData
end

struct AnyMissConstraint <: Constraint
    data::ConstraintData
end

#= Constraint Constructors =#
"""
    RowMissConstraint(x)
Constructor for RowMissConstraint.
"""
RowMissConstraint(x::Int64) = RowMissConstraint(ConstraintData(x, x+1))
RowMissConstraint(x, k)     = RowMissConstraint(ConstraintData(x, x+1))
"""
    RowHitConstraint(x)
Constructor for RowHitConstraint.
"""
RowHitConstraint(x, k)      = RowHitConstraint(ConstraintData(x, k))
"""
    AnyMissConstraint(x)
Constructor for AnyMissConstraint.
"""
AnyMissConstraint(x, k)     = AnyMissConstraint(ConstraintData(x, k))
"""
    AnyHitConstraint(x, k)
Constructor for AnyHitConstraint.
"""
AnyHitConstraint(x, k)      = AnyHitConstraint(ConstraintData(x, k))

