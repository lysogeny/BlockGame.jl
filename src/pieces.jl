LINE_PIECE = Bool[1 1 1 1]

ELL_PIECE = Bool[1 0 0;
                 1 1 1]

MIRROR_ELL_PIECE = Bool[0 0 1;
                        1 1 1]

SQUARE_PIECE = Bool[1 1;
                    1 1]

SQUIGLE_PIECE = Bool[1 1 0;
                     0 1 1]

TEE_PIECE = Bool[1 1 1;
                 0 1 0]

MIRROR_SQUIGLE_PIECE = Bool[0 1 1;
                            1 1 0]

struct Tetronimo 
    color::UInt32
    shape::Matrix{Bool}
end
Tetronimo(color::Vector{UInt8}, shape::Matrix{Bool}) = Tetronimo(MiniFB.mfb_rgb(color...), shape)

Base.size(piece::Tetronimo) = size(piece.shape)

function coordinates(piece::Tetronimo)
    w, h = size(piece.shape)
    [(x-1, y-1) for x in 1:w, y in 1:h if piece.shape[x, y]]
end

function tetronimos_standard() 
    [Tetronimo([0x00, 0xfb, 0xff], LINE_PIECE), # Line, Cyan
     Tetronimo([0x00, 0x00, 0xff], ELL_PIECE), # L, Blue
     Tetronimo([0xff, 0x9f, 0x00], MIRROR_ELL_PIECE), # mirror L, Orange
     Tetronimo([0xff, 0xff, 0x00], SQUARE_PIECE), # Square, Yellow
     Tetronimo([0x00, 0xff, 0x00], SQUIGLE_PIECE), # Squigle, Green
     Tetronimo([0xff, 0x00, 0xff], TEE_PIECE), # T, Purple
     Tetronimo([0xff, 0x00, 0x00], MIRROR_SQUIGLE_PIECE)] # mirrror Squigle, Red
end

function tetronimos_amazing()
    [Tetronimo([0xc0, 0xff, 0xee], LINE_PIECE)]
end
