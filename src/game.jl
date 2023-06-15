BLOCK_SIZE = 32

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
                right!(game.scene)
                render!(game)
            elseif key == MiniFB.KB_KEY_LEFT
                left!(game.scene)
                render!(game)
            elseif key == MiniFB.KB_KEY_UP
                rotate!(game.scene)
                render!(game)
            elseif key == MiniFB.KB_KEY_ESCAPE
                stop!(game.scene)
                render!(game)
            elseif key == MiniFB.KB_KEY_R
                reset!(game.scene)
            end
            # TODO: Figure out why this @info is needed for proper functioning of arrow keys
        end
        if key == MiniFB.KB_KEY_DOWN
            next!(game.scene)
            render!(game)
        end
    end
    @cfunction $f Cvoid (Ptr{Cvoid}, MiniFB.mfb_key, MiniFB.mfb_key_mod, Bool)
end

function run(game::Game)
    @info "Running Game"
    errormonitor(@async buffer_update_loop(game.canvas))
    key_func = keyboard_handler(game)
    push!(game.callbacks, key_func)
    MiniFB.mfb_set_keyboard_callback(game.canvas.window, key_func)
    while game.scene.state != GameExit
        if game.scene.state == GameRunning
            next!(game.scene)
            render!(game)
        end
        sleep(1/5)
    end
    MiniFB.mfb_close(game.canvas.window)
end
