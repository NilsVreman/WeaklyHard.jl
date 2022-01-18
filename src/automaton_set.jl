# Exports
export build_automaton

function build_automaton(Lambda::Set{T}) where {T <: Constraint}
    # @description
    #   The function creates a minimal weakly-hard automaton according to the
    #   set of weakly-hard constraints (Lambda).
    # @param 
    #   Lambda::Set{Constraint}: The set of weakly-hard constraints
    # @returns 
    #   Automaton: The resulting weakly-hard automaton.     

    # Find constraint with maximum K value
    lambda_max_k = reduce(Lambda) do x, y
    x.k > y.k ? x : y end

    # Extract necessary parameters
    k = lambda_max_k.k
    n = _get_nbr_cons_hits(Lambda)

    # Decide IntType
    IntType = _word_type(Lambda, k)

    # IF we are not allowed to miss a single deadline, return a one vertex automaton
    if !is_satisfied(Lambda, consword(IntType(k)) << IntType(1))

        # Initialise Automaton
        initvertex              = WordVertex{Int8}(Int8(Hit))
        automaton               = Automaton{Int8}(initvertex)
        initvertex.hit          = initvertex
        automaton[Int8(Hit)]    = initvertex
        return automaton

    # ELSE IF we are allowed to miss infinite number of misses, return another one vertex automaton
    elseif _allmissespermitted(Lambda)
        # Initialise Automaton
        initvertex              = WordVertex{Int8}(Int8(Hit))
        automaton               = Automaton{Int8}(initvertex)
        initvertex.hit          = initvertex
        initvertex.miss         = initvertex
        automaton[Int8(Hit)]    = initvertex
        return automaton

    # ELSE add next vertex to transitions and continue
    else

        # Initialise automaton
        initvertex = WordVertex{IntType}(consword(IntType(n)))
        automaton = Automaton{IntType}(initvertex)

        for lambda in Lambda
            if typeof(lambda) == RowHitConstraint
                # create a curried function in order to be able to call the same function for both rowhit and all other constraints
                return _build_automaton_set!(Lambda, 
                                            automaton, 
                                            initvertex, 
                                            (x1, x2, x3, x4) -> _initiate_vertex_rh_set!(x1, x2, x3, x4, initvertex.w, k))
            end # if
        end # function

        # Since we know something about the approximate size of the graph,
        # improve performance by setting the size to that automatically.
        sizehint!(automaton.data, binomial(k, n))
        return _build_automaton_set!(Lambda, automaton, initvertex, _initiate_vertex_set!)
    end
end # function

###########################
### Auxiliary Functions ###
###########################

#= Initiate vertex by first shifting vertex to acquire children.
 # Then extend automaton with children (if constraint set satisfied) =#
function _initiate_vertex_set!(Lambda::Set{T}, 
                               automaton::Automaton{S}, 
                               list::_UninitializedList{S},
                               vertex::WordVertex{S}) where {T <: Constraint, S <: Integer}
    (wm, wh) = _children_set(vertex)
    _extend_automaton_set!(Lambda, automaton, list, vertex, wm, wh)
end 
function _initiate_vertex_rh_set!(Lambda::Set{T},
                                  automaton::Automaton{S},
                                  list::_UninitializedList{S},
                                  vertex::WordVertex{S},
                                  wi::S,
                                  k::R) where {T <: Constraint, S <: Integer, R <: Integer}
    (wm, wh) = _children_rh_set(vertex, wi)
    _extend_automaton_rh_set!(Lambda, automaton, list, vertex, wm, wh, k)
end

#= Return the children of vertex, disregarding satisfiability =#
function _children_set(vertex::WordVertex{T}) where {T <: Integer}
    wm = shift(vertex.w, Miss)
    wh = shift(vertex.w, Hit)
    return (wm, wh)
end
function _children_rh_set(vertex::WordVertex{T}, n::T) where {T <: Integer}
    wm = shift_rowhit(vertex.w, Miss, n)
    wh = shift_rowhit(vertex.w, Hit, n)
    return (wm, wh)
end

#= Extend automaton with the children (nm, nh) if they satisfy Lambda =#
function _extend_automaton_set!(Lambda::Set{T},
                                automaton::Automaton{S},
                                list::_UninitializedList{S},
                                vertex::WordVertex{S},
                                wm::S,
                                wh::S) where {T <: Constraint, S <: Integer}

    vertexM = nothing
    vertexH = nothing

    # Check if miss word satisfies constraints and whether it is initialized
    if is_satisfied(Lambda, wm)
        if !haskey(automaton, wm)
            vertexM         = WordVertex{S}(wm)
            automaton[wm]   = vertexM
            _push!(list, vertexM)
        else
            vertexM         = automaton[wm]
        end

        # Add miss path to vertex
        vertex.miss         = vertexM
    end

    # check if hit word is initialised
    if !haskey(automaton, wh)
        vertexH         = WordVertex{S}(wh)
        automaton[wh]   = vertexH
        _push!(list, vertexH)
    else
        vertexH         = automaton[wh]
    end

    # Add hit path to vertex
    vertex.hit = vertexH
end
#= Extend automaton with the children (nm, nh) if they satisfy Lambda =#
function _extend_automaton_rh_set!(Lambda::Set{T},
                                   automaton::Automaton{S},
                                   list::_UninitializedList{S},
                                   vertex::WordVertex{S},
                                   wm::S,
                                   wh::S,
                                   k::R) where {T <: Constraint, S <: Integer, R <: Integer}

    vertexH = nothing
    vertexM = nothing

    # Check if miss word satisfies constraints and whether it is initialized
    if is_satisfied(Lambda, wm)
        wm &= consword(S(k))            # Extracting bits to reduce size of graph
        if !haskey(automaton, wm)
            vertexM         = WordVertex{S}(wm)
            automaton[wm]   = vertexM
            _push!(list, vertexM)
        else
            vertexM         = automaton[wm]
        end

        # Add miss path to vertex
        vertex.miss         = vertexM
    end

    # check if hit word is initialised
    wh &= consword(S(k))            # Extracting bits to reduce size of graph
    if !haskey(automaton, wh)
        vertexH         = WordVertex{S}(wh)
        automaton[wh]   = vertexH
        _push!(list, vertexH)
    else
        vertexH = automaton[wh]
    end

    # Add hit path to vertex
    vertex.hit = vertexH
end

#= Aux function to build automaton =#
function _build_automaton_set!(Lambda::Set{T}, 
                               automaton::Automaton{S}, 
                               initvertex::WordVertex{S}, 
                               f_initiate_vertex!) where {T <: Constraint, S <: Integer}
    
    # First vertex initialisation
    list = _UninitializedList{S}()
    _push!(list, initvertex)
    automaton[initvertex.w] = initvertex

    # Add the remaining vertices to the while loop
    while !isnothing(list.head) # while we have elements to iterate
        # Extract first element to iterate
        vertex  = _pop!(list)

        # Add new feasible vertices to structures and lists
        f_initiate_vertex!(Lambda, automaton, list, vertex)
    end #while

    return automaton
end # function
