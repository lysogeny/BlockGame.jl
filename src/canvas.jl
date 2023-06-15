struct Pixel
    x::Int
    y::Int
    rgb::UInt32
end

mutable struct Canvas
    window::Ptr{Cvoid}
    buffer::Matrix{UInt32}
end

function paint!(buffer::Matrix{UInt32}, pixel::Pixel)
    buffer[pixel.x, pixel.y] = pixel.rgb
end

function Canvas(size::Vararg{Int, 2}) 
    window = MiniFB.mfb_open("BlockGame.jl", size...)
    buffer = zeros(UInt32, size...)
    Canvas(window, buffer)
end

function buffer_update_loop(canvas::Canvas)
    @info "Canvas buffer updater started"
    while true
        state = MiniFB.mfb_update(canvas.window, view(canvas.buffer, :))
        if state != MiniFB.STATE_OK
            break
        end
        sleep(1/60)
    end
end
