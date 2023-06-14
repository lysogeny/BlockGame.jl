struct Pixel
    x::Int
    y::Int
    rgb::UInt32
end

mutable struct Canvas
    window::Ptr{Cvoid}
    buffer::Matrix{UInt32}
    input::Channel{Pixel}
end

function paint!(buffer::Matrix{UInt32}, pixel::Pixel)
    buffer[pixel.x, pixel.y] = pixel.rgb
end

function Canvas(size::Vararg{Int, 2}) 
    window = MiniFB.mfb_open("Tetris.jl", size...)
    buffer = zeros(UInt32, size...)
    input = Channel{Pixel}()
    Canvas(window, buffer, input)
end

function channel_update_loop(canvas::Canvas)
    @info "Canvas channel reader started"
    while isopen(canvas.input)
        pixel = take!(canvas.input)
        paint!(canvas.buffer, pixel)
    end
end

function buffer_update_loop(canvas::Canvas)
    @info "Canvas buffer updater started"
    while isopen(canvas.input)
        state = MiniFB.mfb_update(canvas.window, view(canvas.buffer, :))
        if state != MiniFB.STATE_OK
            break
        end
        sleep(1/60)
    end
end
