mutable struct Scene
    static::Matrix{UInt32}
    position::Vector{Int}
    piece::Piece
    pieces::Vector{Piece}
end

function Scene(size::Vararg{Int, 2})
    static = zeros(UInt32, size...)
    pieces = pieces_standard()
    Scene(static, start_position(size...), rand(pieces), pieces)
end

start_position(w::Int, ::Int) = [Int(floor(w[1]/2)), 1]

start_position(scene::Scene) = start_position(size(scene.static)...)

function add_piece!(scene::Scene, piece::Piece)
    scene.position = start_position(scene)
    scene.piece = piece
    @info "Added piece at ($(scene.position[1]),$(scene.position[2]))"
end

function coordinates(scene::Scene)
    offset_x, offset_y = scene.position
    [(offset_x+x, offset_y+y) for (x, y) in coordinates(scene.piece)]
end

function render(scene::Scene)
    img = copy(scene.static)
    for coordinate in coordinates(scene)
        img[coordinate...] = scene.piece.color
    end
    return img
end

function collide!(scene::Scene)
    #  Compute all positions of the current piece and add it to the canvas
    @info "Committing piece"
    for (x, y) in coordinates(scene)
        scene.static[x, y] = scene.piece.color
    end
    rows = rows_full(scene)
    if length(rows) > 0
        clear_rows!(scene, rows)
    end
    add_piece!(scene, rand(scene.pieces))
    scene.piece = rand(scene.pieces)
end

function iscollided(scene::Scene)
    # Compute all positions of the current piece and check if something is directly underneath
    h = size(scene.static, 2)
    for (x, y) in coordinates(scene)
        if y == h
            return true
        end
        if scene.static[x, y+1] > 0
            return true
        end
    end
    return false
end

function rows_full(scene::Scene)
    rows = Int[]
    for i in axes(scene.static, 2)
        if all(scene.static[:, i] .> 0)
            push!(rows, i)
        end
    end
    return rows
end

function clear_rows!(scene::Scene, rows::Vector{Int})
    # Slice rows out of the picture somehow.
    w, h = size(scene.static)
    @debug "old size ($w, $h)"
    n_remove = length(rows)
    rows_keep = setdiff(axes(scene.static, 2), rows)
    rows_append = zeros(UInt32, w, n_remove)
    static = hcat(rows_append, scene.static[:, rows_keep])
    w_new, h_new = size(static)
    @debug "new size ($w_new, $h_new)"
    scene.static = static
end

function left!(scene::Scene)
    # TODO: don't move when there is a block next to us
    if scene.position[1] > 1
        scene.position[1] -= 1
    end
end

function right!(scene::Scene)
    # TODO: don't move when there is a block next to us
    if scene.position[1] < size(scene.static, 1)-1
        scene.position[1] += 1
    end
end

function rotate!(scene::Scene)
    scene.piece.shape = scene.piece.shape'[:, reverse(axes(scene.piece.shape, 1))]
end

function next!(scene::Scene)
    # Check collisions and commit if they happened.
    @info "Updating scene"
    if iscollided(scene)
        @debug "Detected collision"
        collide!(scene)
    else
        # Advance currently moving piece
        @debug "Advancing position"
        scene.position[2] += 1
    end
end
