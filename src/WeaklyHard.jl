module WeaklyHard

#= Uses for all includes etc =#
using LinearAlgebra

#= Types and constructors =#
include("types.jl")

#= Includes =#
include("alphabet.jl")          # Defines the functions on the Words and Characters
include("constraints.jl")       # Defines constraints, dominance relations, equivalences, and satisfaction functions
include("dominant_set.jl")      # Defines functions to generate the dominant subset of a constraint set.

include("datastructures.jl")    # Defines the datastructures necessary to improve execution time of the automaton construction.
include("automaton_single.jl")  # Defines the automata generation functions for single constraints
include("automaton_set.jl")     # Defines the automata generation functions for sets of constraints

include("automaton_util.jl")    # Defines the utility functions applied to the automaton
include("sequences.jl")         # Defines functions that generate sequences of a specific automata construction.
include("printing.jl")          # Defines the printing statements for the existing structs

end # module
