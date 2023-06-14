BLOCK_SIZE = 32

mutable struct Scene
    static::Matrix{UInt32}
    position::Vector{Int}
    piece::Union{Tetronimo}
    pieces::Vector{Tetronimo}
end

function Scene(size::Vararg{Int, 2})
    static = zeros(UInt32, size...)
    pieces = tetronimos_amazing()
    Scene(static, start_position(size...), rand(pieces), pieces)
end

start_position(w::Int, ::Int) = [Int(floor(w[1]/2)), 1]

start_position(scene::Scene) = start_position(size(scene.static)...)

function add_piece!(scene::Scene, piece::Tetronimo)
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

function commit_piece!(scene::Scene)
    #  Compute all positions of the current piece and add it to the canvas
    @info "Committing piece"
    for (x, y) in coordinates(scene)
        scene.static[x, y] = scene.piece.color
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

function istetris(scene::Scene)
    rows = Int[]
    for i in axes(scene.static, 2)
        if all(scene.static[i,:] .> 0)
            push!(rows, i)
        end
    end
    return rows
end

function left!(scene::Scene)
    if scene.position[1] > 1
        scene.position[1] -= 1
    end
end

function right!(scene::Scene)
    if scene.position[1] < size(scene.static, 1)
        scene.position[1] += 1
    end
end

function clear_rows!(scene::Scene, rows::Vector{Int})
    # Slice rows out of the picture somehow.
    scene[rows,:]
end

function next!(scene::Scene)
    # Check collisions and commit if they happened.
    if iscollided(scene)
        commit_piece!(scene)
    else
        # Advance currently moving piece
        scene.position[2] += 1
    end
end

mutable struct Game
    scene::Scene
    canvas::Canvas
    block_size::Int
    callbacks::Vector{Base.CFunction}
end

function Game(size::Vararg{Int, 2}; block_size=BLOCK_SIZE)
    scene = Scene(size...)
    canvas_size = block_size .* size
    canvas = Canvas(canvas_size...)
    Game(scene, canvas, block_size, Base.CFunction[])
end

function render!(game::Game)
    img = render(game.scene)
    s = game.block_size
    for x in axes(img, 1), y in axes(img, 2)
        # 1, 16; 17, 32; 33, 48; 49, 64
        game.canvas.buffer[((x-1)*s+1):(s * x), ((y-1)*s+1):(s * y)] .= img[x, y]
    end
end

function keyboard_handler(game::Game)
    f = function(window::Ptr{Cvoid}, key::MiniFB.mfb_key, mod::MiniFB.mfb_key_mod, isPressed::Bool)
        if isPressed
            if key == MiniFB.KB_KEY_RIGHT
                @info "Move right"
                right!(game.scene)
            elseif key == MiniFB.KB_KEY_LEFT
                @info "Move left"
                left!(game.scene)
            end
            @debug "Move completed"
        end
    end
    @cfunction $f Cvoid (Ptr{Cvoid}, MiniFB.mfb_key, MiniFB.mfb_key_mod, Bool)
end

function run(game::Game)
    @info "Running Tetris"
    @async buffer_update_loop(game.canvas)
    key_func = keyboard_handler(game)
    push!(game.callbacks, key_func)
    MiniFB.mfb_set_keyboard_callback(game.canvas.window, key_func)
    while true
        next!(game.scene)
        render!(game)
        sleep(1/10)
    end
end
