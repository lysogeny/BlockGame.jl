@enum CanvasState begin
    CanvasOkay
    CanvasExit
end

mutable struct Canvas
    window::Ptr{Cvoid}
    buffer::Matrix{UInt32}
    state::CanvasState
end

function Canvas(size::Vararg{Int, 2}) 
    window = MiniFB.mfb_open("BlockGame.jl", size...)
    buffer = zeros(UInt32, size...)
    Canvas(window, buffer, CanvasOkay)
end

function buffer_update_loop(canvas::Canvas)
    @info "Canvas buffer updater started"
    state = MiniFB.mfb_update(canvas.window, view(canvas.buffer, :))
    while (canvas.state != CanvasExit) && (state == MiniFB.STATE_OK)
        state = MiniFB.mfb_update(canvas.window, view(canvas.buffer, :))
        sleep(1/60)
    end
end
