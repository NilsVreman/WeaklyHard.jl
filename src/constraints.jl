export is_dominant,
    is_equivalent,
    is_satisfied

#################
### Overloads ###
#################

#= Override get function for structs of type Constraint =#
function Base.getproperty(c::Constraint, s::Symbol)
    if s === :x || s === :k
        return getproperty(c.data, s)
    end # if
    getfield(c, s)
end # function

#####################
### Aux Functions ###
#####################

#= get the number of hits necessary in a window according to lambda =#
_get_nbr_cons_hits(lambda::RowHitConstraint)     = lambda.x
_get_nbr_cons_hits(lambda::RowMissConstraint)    = lambda.k - lambda.x
_get_nbr_cons_hits(lambda::AnyHitConstraint)     = lambda.x
_get_nbr_cons_hits(lambda::AnyMissConstraint)    = lambda.k - lambda.x
function _get_nbr_cons_hits(Lambda::Set{T}) where {T <: Constraint}
    lambda_max_n = reduce(Lambda) do x, y
    (_get_nbr_cons_hits(x) > _get_nbr_cons_hits(y)) ? x : y end
    return _get_nbr_cons_hits(lambda_max_n)
end # function

#= get the maximum number of consecutive misses permissed a window according to Lambda =#
_get_nbr_cons_misses(lambda::RowHitConstraint)     = (lambda.k >= 2*lambda.x) ? lambda.k - 2*lambda.x + 1 : 0
_get_nbr_cons_misses(lambda::RowMissConstraint)    = lambda.x
_get_nbr_cons_misses(lambda::AnyHitConstraint)     = lambda.k - lambda.x
_get_nbr_cons_misses(lambda::AnyMissConstraint)    = lambda.x
function _get_nbr_cons_misses(Lambda::Set{T}) where {T <: Constraint}
    lambda_min_z = reduce(Lambda) do x, y
    (_get_nbr_cons_misses(x) < _get_nbr_cons_misses(y)) ? x : y end
    return _get_nbr_cons_misses(lambda_min_z)
end # function

#= Returns true if a sequence of all misses is permitted =#
_allmissespermitted(lambda::RowHitConstraint)     = lambda.x == 0
_allmissespermitted(lambda::RowMissConstraint)    = lambda.x == lambda.k
_allmissespermitted(lambda::AnyHitConstraint)     = lambda.x == 0
_allmissespermitted(lambda::AnyMissConstraint)    = lambda.x == lambda.k
function _allmissespermitted(Lambda::Set{T}) where {T <: Constraint}
    for lambda in Lambda
        if !_allmissespermitted(lambda)
            return false
        end # if
    end # for
    return true
end # function

#= Extends word w with (k-n) set bits from position n to position k (counting from right to left) =#
_extendword(w::T, n, k) where {T <: Integer} = (consword(T(k-n)) << T(n)) | w

##############################
### Satisfaction Functions ###
##############################

#= Returns whether the word/integer w satisfies the RowHitConstraint lambda =#
function is_satisfied(lambda::RowHitConstraint, w::T) where {T <: Integer}
    # Check if all misses is permitted
    if w == 0
        return _allmissespermitted(lambda)
    end

    # Append hits at beginning and end of sequence w 
    cons_w  = consword(T(lambda.x))
    w       = (((cons_w << nbits(w)) | T(w)) << T(lambda.x)) | cons_w
    n       = nbits(w)
    cmp_w   = consword(T(lambda.k))

    # Add hits to beginning of word if word is shorter than window
    if n < lambda.k
        w   = _extendword(w, n, lambda.k)
        n   = lambda.k
    end

    # Iterate sequence w to check if constraint is satisfied
    while n >= lambda.k
        if nconsbits(w & cmp_w) < lambda.x
            return false
        end # if
        w >>= T(1)
        n -= T(1)
    end # for
    return true
end # function

#= Returns whether the word/integer w satisfies the RowMissConstraint lambda =#
function is_satisfied(lambda::RowMissConstraint, w::T) where {T <: Integer}
    # Check if all misses is permitted
    if w == 0
        return _allmissespermitted(lambda)
    end

    # Add hits to beginning of word if word is shorter than window
    n = nbits(w)
    if n < lambda.k
        w   = _extendword(w, n, lambda.k)
        n   = lambda.k
    end

    # Iterate sequence w to check if constraint is satisfied
    cons_w = consword(T(lambda.x + 1))
    while n >= lambda.k
        if (w & cons_w) == 0 # all misses
            return false
        end # if
        w >>= T(1)
        n -= T(1)
    end # for
    return true
end # function

#= Returns whether the word/integer w satisfies the AnyHitConstraint lambda =#
function is_satisfied(lambda::AnyHitConstraint, w::T) where {T <: Integer}
    # Check if all misses is permitted
    if w == 0
        return _allmissespermitted(lambda)
    end

    # Add hits to beginning of word if word is shorter than window
    n = nbits(w)
    if n < lambda.k
        w   = _extendword(w, n, lambda.k)
        n   = lambda.k
    end
    
    # Iterate sequence w to check if constraint is satisfied
    cons_w = consword(T(lambda.k))
    while n >= lambda.k
        if nsetbits(w & cons_w) < lambda.x
            return false
        end # if
        w >>= T(1)
        n -= T(1)
    end # for
    return true
end # function

#= Returns whether the word/integer w satisfies the AnyMissConstraint lambda =#
function is_satisfied(lambda::AnyMissConstraint, w::T) where {T <: Integer}    
    # Check if all misses is permitted
    if w == 0
        return _allmissespermitted(lambda)
    end

    # Add hits to beginning of word if word is shorter than window
    n = nbits(w)
    if n < lambda.k
        w   = _extendword(w, n, lambda.k)
        n   = lambda.k
    end

    # Iterate sequence w to check if constraint is satisfied
    cons_w = consword(T(lambda.k))
    while n >= lambda.k
        if nsetbits(w & cons_w) < lambda.k - lambda.x
            return false
        end # if
        w >>= T(1)
        n -= T(1)
    end # for
    return true
end # function

#= Returns whether the word/integer w satisfies the Constraint Set Lambda =#
function is_satisfied(Lambda::Set{T}, w::S) where {T <: Constraint, S <: Integer}
    for lambda in Lambda
        if !is_satisfied(lambda, w)
            return false
        end # if
    end # for
    return true
end # function

####################################
### Domination Multiple Dispatch ###
####################################

function is_dominant(lambda1::AnyMissConstraint, lambda2::AnyMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyMiss, lambda2 = AnyMiss

    return is_dominant(AnyHitConstraint(lambda1.k-lambda1.x, lambda1.k), AnyHitConstraint(lambda2.k-lambda2.x, lambda2.k))

end # function

function is_dominant(lambda1::AnyMissConstraint, lambda2::AnyHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyMiss, lambda2 = AnyHit

    return is_dominant(AnyHitConstraint(lambda1.k-lambda1.x, lambda1.k), lambda2)

end # function

function is_dominant(lambda1::AnyMissConstraint, lambda2::RowMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyMiss, lambda2 = RowMiss

    return is_dominant(AnyHitConstraint(lambda1.k-lambda1.x, lambda1.k), AnyHitConstraint(1, lambda2.k))

end # function

function is_dominant(lambda1::AnyMissConstraint, lambda2::RowHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyMiss, lambda2 = RowHit

    return is_dominant(AnyHitConstraint(lambda1.k-lambda1.x, lambda1.k), lambda2)

end # function

function is_dominant(lambda1::AnyHitConstraint, lambda2::AnyMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyHit, lambda2 = AnyMiss

    return is_dominant(lambda1, AnyHitConstraint(lambda2.k-lambda2.x, lambda2.k))

end # function

function is_dominant(lambda1::AnyHitConstraint, lambda2::AnyHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyHit, lambda2 = AnyHit

    # Variable extraction
    x1, k1 = lambda1.x, lambda1.k
    x2, k2 = lambda2.x, lambda2.k

    # Checking the trivial case
    if x1 == k1
        return true
    elseif x2 == k2
        return false
    end

    # Domination condition
    return x2 <= max(floor(Int64, k2 / k1) * x1, k2 + ceil(Int64, k2 / k1) * (x1 - k1))

end # function

function is_dominant(lambda1::AnyHitConstraint, lambda2::RowMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyHit, lambda2 = RowMiss

    return is_dominant(lambda1, AnyHitConstraint(1, lambda2.k))

end # function

function is_dominant(lambda1::AnyHitConstraint, lambda2::RowHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = AnyHit, lambda2 = RowHit

    # Variable extraction
    x1, k1 = lambda1.x, lambda1.k
    x2, k2 = lambda2.x, lambda2.k
    z1 = k1-x1

    # Checking trivial case
    if x1 == k1
        return true
    elseif 2*x2 > k2
        return false
    elseif x2 == 0
        return true
    elseif x1 == 0 
        return false
    end

    # Domination condition
    return x2 <= min(floor(Int64, k2/(z1+1)), ceil(Int64, x1/z1))

end # function

function is_dominant(lambda1::RowMissConstraint, lambda2::AnyMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowMiss, lambda2 = AnyMiss

    return is_dominant(AnyHitConstraint(1, lambda1.k), AnyHitConstraint(lambda2.k-lambda2.x, lambda2.k))

end # function

function is_dominant(lambda1::RowMissConstraint, lambda2::AnyHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowMiss, lambda2 = AnyHit

    return is_dominant(AnyHitConstraint(1, lambda1.k), lambda2)

end # function

function is_dominant(lambda1::RowMissConstraint, lambda2::RowMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowMiss, lambda2 = RowMiss

    return is_dominant(AnyHitConstraint(1, lambda1.k), AnyHitConstraint(1, lambda2.k))

end # function

function is_dominant(lambda1::RowMissConstraint, lambda2::RowHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowMiss, lambda2 = RowHit

    return is_dominant(AnyHitConstraint(1, lambda1.k), lambda2)

end # function

function is_dominant(lambda1::RowHitConstraint, lambda2::AnyMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowHit, lambda2 = AnyMiss

    return is_dominant(lambda1, AnyHitConstraint(lambda2.k-lambda2.x, lambda2.k))

end # function

function is_dominant(lambda1::RowHitConstraint, lambda2::AnyHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowHit, lambda2 = AnyHit
    
    # Variable Extraction
    x1, k1 = lambda1.x, lambda1.k
    x2, k2 = lambda2.x, lambda2.k
    z1 = k1-2*x1+1

    # Checking trivial case
    if 2*x1 > k1
        return true
    elseif x2 == k2
        return false
    elseif x2 == 0
        return true
    elseif x1 == 0 
        return false
    end

    # Domination condition
    return x2 <= max(x1*floor(Int64, k2/(z1+x1)), k2 - floor(Int64, k2/(z1+x1))*z1 - z1)

end # function

function is_dominant(lambda1::RowHitConstraint, lambda2::RowMissConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowHit, lambda2 = RowMiss

    return is_dominant(lambda1, AnyHitConstraint(1, lambda2.k))

end # function

function is_dominant(lambda1::RowHitConstraint, lambda2::RowHitConstraint)
    # Returns if lambda1 dominates lambda2: lambda1 <= lambda2
    # lambda1 = RowHit, lambda2 = RowHit
    
    # Variable extraction
    x1, k1 = lambda1.x, lambda1.k
    x2, k2 = lambda2.x, lambda2.k

    # Checking trivial case
    if 2*x1 > k1
        return true
    elseif 2*x2 > k2
        return false
    elseif x2 == 0
        return true
    elseif x1 == 0 
        return false
    end

    # Domination condition
    return (k2 < k1 && x2 <= x1 - ceil(Int64,  (k1-k2)/2 )) || (k2 >= k1 && x2 <= x1)

end # function

### Equivalence function
function is_equivalent(lambda1::Constraint, lambda2::Constraint)
    # Returns if lambda1 is equivalent to lambda2: lambda1 === lambda2

    return is_dominant(lambda1, lambda2) && is_dominant(lambda2, lambda1)

end # function
