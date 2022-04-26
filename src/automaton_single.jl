# Exports
export build_automaton

function build_automaton(lambda::T) where {T <: Constraint}

    # Find constraint with maximum K value
    # Extract necessary parameters
    k = lambda.k
    n = _get_nbr_cons_hits(lambda)

    # Decide IntType
    IntType = _word_type(lambda, k)

    # IF we are not allowed to miss a single deadline, return a one vertex automaton
    if !is_satisfied(lambda, consword(IntType(k)) << IntType(1))

        # Initialise Automaton
        initvertex              = WordVertex{Int8}(Int8(Hit))
        automaton               = Automaton{Int8}(initvertex)
        initvertex.hit          = initvertex
        automaton[Int8(Hit)]    = initvertex
        return automaton

    # ELSE IF we are allowed to miss infinite number of misses, return another one vertex automaton
    elseif _allmissespermitted(lambda)
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
        sizehint!(automaton.data, _minimal_size(lambda))

        # If we have a rowhit constraint, change building method
        if typeof(lambda) == RowHitConstraint
            z = _get_nbr_cons_misses(lambda)
            return _build_automaton_rh!(lambda, 
                                        automaton, 
                                        initvertex, 
                                        IntType(z),
                                        IntType(n), 
                                        IntType(k))
        end # if

        # Else
        return _build_automaton!(lambda, 
                                 automaton, 
                                 initvertex)
    end
end # function

##################################
### Auxiliary Functions for RH ###
##################################

function _initiate_vertex_rh!(lambda::T, 
                              automaton::Automaton{S},
                              list::_UninitializedList{S}, 
                              miss_list::Vector{WordVertex{S}},
                              vertex::WordVertex{S},
                              initword::S,
                              k::S) where {T <: Constraint, S <: Integer}
    (wm, wh) = _children_rh(vertex, initword)
    _extend_automaton_rh!(lambda, automaton, list, miss_list, vertex, wm, wh, k)
end # function

#= Extend automaton with the children (nm, nh) if they satisfy lambda =#
function _extend_automaton_rh!(lambda::T,
                               automaton::Automaton{S},
                               list::_UninitializedList{S},
                               miss_list::Vector{WordVertex{S}},
                               vertex::WordVertex{S},
                               wm::S,
                               wh::S,
                               k::S) where {T <: Constraint, S <: Integer}
    vertexH = nothing

    # Check if miss word satisfies constraints and whether it is initialized
    if is_satisfied(lambda, wm)
        vertex.miss = miss_list[_nbr_misses_permitted(lambda, vertex.w, k)]
    end

    # Check how many consecutive misses we are permitted, 
    #   If it is more than 0: add to the automata (unless already present)
    if _nbr_misses_permitted(lambda, wh, k) > 0
        # check if hit word is initialised
        if !haskey(automaton, wh)
            vertexH         = WordVertex{S}(wh)
            automaton[wh]   = vertexH
            _push!(list, vertexH)
        else
            vertexH = automaton[wh]
        end
    else
        vertexH = automaton[consword(S(trailing_ones(wh)))]
    end

    # Add hit path to vertex
    vertex.hit = vertexH
end

#= Return the children of vertex, disregarding satisfiability =#
function _children_rh(vertex::WordVertex{T}, initword::T) where {T <: Integer}
    wm = shift_rowhit(vertex.w, Miss, initword)
    wh = shift_rowhit(vertex.w, Hit, initword)
    return (wm, wh)
end

# Returns how many consecutive misses we permit following w
function _nbr_misses_permitted(lambda::T, w::S, k::S) where {T <: Constraint, S <: Integer}
    for z in S(1):k
        if !is_satisfied(lambda, (w << (z+S(1))) | S(1))
            return z-S(1)
        end
    end
    return k
end # function

#= Add first nodes to the automaton by adding the maximum consecutive miss path to it. =#
function _add_miss_path_rh!(lambda::T, 
                            automaton::Automaton{S},
                            list::_UninitializedList{S}, 
                            vertex::WordVertex{S},
                            z::S,
                            n::S,
                            k::S) where {T <: Constraint, S <: Integer}
    # Add "hit path" to automaton
    v = vertex
    for n_ in n-S(1):S(-1):S(1)
        w               = consword(n_)
        v_prior         = WordVertex{S}(w)
        v_prior.hit     = v
        automaton[w]    = v_prior
        v               = v_prior
    end # for

    # A list where each index "i" corresponds to the vertex with "i" more deadlines tolerated  
    aux_list = Vector{WordVertex{S}}(undef, z+1)

    # Add "miss path" to automaton
    v       = vertex
    vertexM = nothing
    for z_ in z+S(1):S(-1):S(1)
        aux_list[z_]    = v
        (wm, wh)        = _children_rh(v, consword(n))

        # Check if miss word satisfies constraints and whether it is initialized
        if is_satisfied(lambda, wm)
            vertexM         = WordVertex{S}(wm)
            automaton[wm]   = vertexM

            # Add miss path to vertex
            v.miss         = vertexM
        end

        # check if hit word is initialised
        if _nbr_misses_permitted(lambda, wh, k) > 0
            if !haskey(automaton, wh)
                vertexH         = WordVertex{S}(wh)
                automaton[wh]   = vertexH
                _push!(list, vertexH)
            else
                vertexH = automaton[wh]
            end
        else
            vertexH = automaton[consword(S(trailing_ones(wh)))]
        end

        # Add hit path to vertex
        v.hit = vertexH

        v = vertexM
    end # for

    return aux_list

end # function

#= Build the automaton =#
function _build_automaton_rh!(lambda::T, 
                              automaton::Automaton{S}, 
                              initvertex::WordVertex{S}, 
                              z::S,
                              n::S,
                              k::S) where {T <: Constraint, S <: Integer}
    # First initialize the necessary miss path in the graph
    list                    = _UninitializedList{S}()
    automaton[initvertex.w] = initvertex
    miss_list = _add_miss_path_rh!(lambda, automaton, list, initvertex, z, n, k)

    # Add the remaining vertices to the while loop
    while !isnothing(list.head) # while we have elements to iterate
        # Extract first element to iterate
        vertex = _pop!(list)

        # Add new feasible vertices to structures and lists
        _initiate_vertex_rh!(lambda, automaton, list, miss_list, vertex, consword(n), k)
    end #while

    return automaton
end # function

##########################################
### Auxiliary Functions for RM, AM, AH ###
##########################################

function _initiate_vertex!(lambda::T, 
                           automaton::Automaton{S},
                           list::_UninitializedList{S}, 
                           vertex::WordVertex{S}) where {T <: Constraint, S <: Integer}
    (wm, wh) = _children(vertex)
    _extend_automaton!(lambda, automaton, list, vertex, wm, wh)
end # function

#= Extend automaton with the children (nm, nh) if they satisfy lambda =#
function _extend_automaton!(lambda::T,
                            automaton::Automaton{S},
                            list::_UninitializedList{S},
                            vertex::WordVertex{S},
                            wm::S,
                            wh::S) where {T <: Constraint, S <: Integer}
    vertexM = nothing
    vertexH = nothing

    # Check if miss word satisfies constraints and whether it is initialized
    if is_satisfied(lambda, wm)
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

#= Return the children of vertex, disregarding satisfiability =#
function _children(vertex::WordVertex{T}) where {T <: Integer}
    wm = shift(vertex.w, Miss)
    wh = shift(vertex.w, Hit)
    return (wm, wh)
end

#= Building the automaton =#
function _build_automaton!(lambda::T, 
                           automaton::Automaton{S}, 
                           initvertex::WordVertex{S}) where {T <: Constraint, S <: Integer}
    # First initialize the necessary miss path in the graph
    list                    = _UninitializedList{S}()
    automaton[initvertex.w] = initvertex
    _push!(list, initvertex)

    # Add the remaining vertices to the while loop
    while !isnothing(list.head) # while we have elements to iterate
        # Extract first element to iterate
        vertex = _pop!(list)

        # Add new feasible vertices to structures and lists
        _initiate_vertex!(lambda, automaton, list, vertex)
    end #while

    return automaton
end # function
