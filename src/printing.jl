#################
### Automaton ###
#################

function Base.show(io::IO, automaton::Automaton{T}) where {T <: Integer}
    if isempty(automaton.data)
        print(io, "Uninitialized $(typeof(automaton))")

    else
        k = maximum(x -> nbits(x), keys(automaton.data))

        println(io, "$(typeof(automaton)) with $(length(automaton)) vertices:")
        println(io, "{")
        i = 1
        for p in automaton.data
            if i >= 21
                println(io, "\t...")
                break
            end
            println(io, "\t$(_compactstring(p[2], k))")
            i +=1
        end
        print(io, "} with head: $(automaton.head)")
    end
end

##################
### WordVertex ###
##################

#= WordVertex - Returns a string representation of the word/integer corresponding to n =#
_wordstring(n::WordVertex{BigInt})                              = bitstring(n.w)
_wordstring(n::WordVertex{T}) where {T <: Integer}              = bitstring(n.w)[end-nbits(n.w)+1:end]

#= WordVertex - Returns a string representation of the word/integer corresponding to the child s of n =#
_childstring(n::WordVertex{T}, s::Symbol) where {T <: Integer}  = !_childexists(n, s) ? '-' : _wordstring(getfield(n, s))

#= WordVertex - Returns a compact bitstring representation of the WordVertex n (of length k) =#
function _compactstring(n::WordVertex{T}, k::Integer) where {T <: Integer}
    "$(typeof(n))($(bitstring(n.w)[end-k+1:end]) => "*
        "$(!_childexists(n, :miss) ? '-'^k : bitstring(n.miss.w)[end-k+1:end]), " * 
        "$(bitstring(n.hit.w)[end-k+1:end]))"
end # function
function _compactstring(n::WordVertex{BigInt}, k::Integer)
    "$(typeof(n))($(bitstring(n.w)) => "*
        "$(!_childexists(n, :miss) ? '-' : bitstring(n.miss.w)), " * 
        "$(bitstring(n.hit.w)))"
end # function

#= WordVertex - Printing =#
function Base.String(n::WordVertex{T}) where {T <: Integer}
    "$(typeof(n))($(_wordstring(n)) => $(_childstring(n, :miss)), $(_childstring(n, :hit)))"
end
function Base.show(io::IO, n::WordVertex{T}) where {T <: Integer}
    print(io, String(n))
end

################
### Alphabet ###
################

"""
    bitstring(w::BigInt [, n::Integer])

A String giving the literal bit representation of a big integer `w`.
If `n` is specified, it pads the bit representation to contain _at least_ `n` characters.

## Examples

```julia-repl
julia> bitstring(BigInt(4))
"100"

julia> bitstring(BigInt(4), 5)
"00100"
``` 
"""
Base.bitstring(w::BigInt)                    = string(w, base = 2)
Base.bitstring(w::BigInt, N::Integer)        = string(w, pad = unsigned(N), base = 2)

##################
### Constraint ###
##################

function Base.show(io::IO, lambda::Constraint)
    print(io, typeof(lambda))
    print(io, (lambda.x, lambda.k))
end
