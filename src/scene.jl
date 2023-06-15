mutable struct ScenePiece
    coordinates::Matrix{Int}
    offset::Vector{Int}
    color::UInt32
end

function ScenePiece(piece::Piece, offset::Vector{Int})
    coords = coordinates(piece)
    coords = hcat([[x, y] for (x, y) in coordinates(piece)]...)
    shift = Int.(ceil.(maximum(coords, dims=2)/2))
    coords .-= shift
    ScenePiece(coords, offset, piece.color)
end

function coordinates(piece::ScenePiece)
    [[x+piece.offset[1], y+piece.offset[2]] for (x, y) in eachcol(piece.coordinates)]
end

function visible_coordinates(piece::ScenePiece)
    [(x, y) for (x, y) in coordinates(piece)
     if y > 0]
end

function left!(piece::ScenePiece)
    piece.offset[1] -= 1
end

function right!(piece::ScenePiece)
    piece.offset[1] += 1
end

function down!(piece::ScenePiece)
    piece.offset[2] += 1
end

function rotate!(piece::ScenePiece)
    @debug "Unrotated piece is at" piece.coordinates
    rot = [0 -1;
           1  0]
    piece.coordinates = hcat([rot * c for c in eachcol(piece.coordinates)]...)
    @debug "Rotated piece is at" piece.coordinates
end

@enum GameState begin
    GameRunning
    GameOver
    GameExit
end

mutable struct Scene
    static::Matrix{UInt32}
    piece::ScenePiece
    pieces::Vector{Piece}
    state::GameState
end

function Scene(size::Vararg{Int, 2})
    size = (size[1], size[2])
    static = zeros(UInt32, size...)
    pieces = pieces_standard()
    piece = ScenePiece(rand(pieces), start_position(size...))
    Scene(static, piece, pieces, GameRunning)
end

start_position(w::Int, ::Int) = [Int(floor(w[1]/2)), -4]

start_position(scene::Scene) = start_position(size(scene.static)...)

function add_piece!(scene::Scene, piece::Piece)
    scene.piece = ScenePiece(piece, start_position(scene))
end

function render(scene::Scene)
    img = copy(scene.static)
    visible_coords = visible_coordinates(scene.piece)
    for coordinate in visible_coords
        img[coordinate...] = scene.piece.color
    end
    return img
end

function collide!(scene::Scene)
    #  Compute all positions of the current piece and add it to the canvas
    @info "Committing piece"
    for (x, y) in coordinates(scene.piece)
        if y < 1
            scene.state = GameOver
            return
        end
        scene.static[x, y] = scene.piece.color
    end
    rows = rows_full(scene)
    if length(rows) > 0
        clear_rows!(scene, rows)
    end
    add_piece!(scene, rand(scene.pieces))
end

function iscollided(scene::Scene)
    # Compute all positions of the current piece and check if something is directly underneath
    h = size(scene.static, 2)
    for (x, y) in coordinates(scene.piece)
        if y < 0
            @debug "Skipping check on ($x, $y)"
            continue
        end
        if y == h
            @debug "Last line on ($x, $y)."
            return true
        end
        underneath = scene.static[x, y+1]
        if (underneath > 0)
            @debug "There is a block beneath ($x, $y) with value $underneath"
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

function isleftfree(scene::Scene)
    for coordinate in visible_coordinates(scene.piece)
        if coordinate[1] == 1 || 
            scene.static[coordinate[1]-1,coordinate[2]] > 0
            return false
        end
    end
    return true
end

function isrightfree(scene::Scene)
    for coordinate in visible_coordinates(scene.piece)
        if coordinate[1] == size(scene.static, 1) || 
            scene.static[coordinate[1]+1,coordinate[2]] > 0

            return false
        end
    end
    return true
end

function left!(scene::Scene)
    if isleftfree(scene) && scene.state == GameRunning
        left!(scene.piece)
    end
end

function right!(scene::Scene)
    if isrightfree(scene) && scene.state == GameRunning
        right!(scene.piece)
    end
end

function rotate!(scene::Scene)
    if scene.state == GameRunning
        rotate!(scene.piece)
    end
end

function reset!(scene::Scene)
    scene.state = GameRunning
    for i in eachindex(scene.static)
        scene.static[i] = UInt32(0x000000)
    end
    add_piece!(scene, rand(scene.pieces))
end

function stop!(scene::Scene)
    @info "It's over"
    scene.state = GameExit
end

function next!(scene::Scene)
    # Check collisions and commit if they happened.
    @info "Updating scene"
    if iscollided(scene)
        @debug "Detected collision"
        collide!(scene)
    elseif scene.state == GameRunning
        # Advance currently moving piece
        down!(scene.piece)
    end
end

