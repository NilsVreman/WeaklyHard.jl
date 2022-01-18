export consword

###########################
### Auxiliary Functions ###
###########################

#= Create a word with n consecutive set bits as least significant =#
consword(n::T) where {T <: Integer} = (T(1) << n) - T(1)

#= Counts the number of bits in the integer w =#
nbits(w::T) where {T <: Integer} = 8*sizeof(T) - leading_zeros(w)
nbits(w::BigInt)                 = (w == 0) ? Int64(0) : ndigits(w, base=2)

#= Counting the number of set bits in the integer w =#
nsetbits(w::T) where {T <: Integer} = count_ones(w)

#= Counting the maximum number of consecutive set bits in an integer w =#
function nconsbits(w::T) where {T <: Integer}
    n = 0
    while w != Miss
        w &= (w << T(1))
        n += 1
    end # while
    n
end # function

#################
### Functions ###
#################

#= 
 = Left shifts bits once and adds new bit as LSB (according to character c). 
 = Removes the MSB if character is a Hit 
 =#
function shift(w::T, c) where {T <: Integer}
    if c == Miss
        return w << T(1)
    else
        return ((w << T(1)) | T(1)) & consword(T(nbits(w)))
    end
end

#= 
 = Left shifts bits once and adds new bit as LSB (according to character c). 
 = Returns the word n if the bits in nw coincide with the ones in n
 =#
function shift_rowhit(w::T, c, n::T) where {T <: Integer}
    #= Shift bits according to charcter c and default to n if last few char are equal to n =#
    if c == Miss
        w <<= T(1)
    else
        w = (w << T(1)) | T(1)
    end
    return (w & n == n) ? n : w
end
