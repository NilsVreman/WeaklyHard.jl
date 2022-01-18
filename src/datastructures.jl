#=
 # LinkedList of not yet treated vertices
 =#

mutable struct _ListEle{T <: Integer}
    vertex::WordVertex{T}
    next::Union{_ListEle{T}, Nothing}

    # _ListEle constructors
    _ListEle{T}(vertex, next) where {T <: Integer}  = new(vertex, next)
end # struct

mutable struct _UninitializedList{T <: Integer}
    n::Int32
    head::Union{_ListEle{T}, Nothing}

    # _UninitializedList constructors
    _UninitializedList{T}() where {T <: Integer}    = new(0, nothing)
end

function _push!(l::_UninitializedList{T}, v::WordVertex{T}) where {T <: Integer}
    l.n += 1
    l.head = _ListEle{T}(v, l.head) # Create list element
end

function _pop!(l::_UninitializedList{T}) where {T <: Integer}
    if (isnothing(l.head))
        error("pop!: Can't pop from an empty list")
        return
    end

    l.n     -= 1
    v       = l.head.vertex
    l.head  = l.head.next
    return v
end
