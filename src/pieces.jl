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

mutable struct Piece 
    color::UInt32
    shape::Matrix{Bool}
end
Piece(color::Vector{UInt8}, shape::Matrix{Bool}) = Piece(MiniFB.mfb_rgb(color...), shape)

Base.size(piece::Piece) = size(piece.shape)

function coordinates(piece::Piece)
    w, h = size(piece.shape)
    [(x-1, y-1) for x in 1:w, y in 1:h if piece.shape[x, y]]
end

function pieces_standard() 
    [Piece([0x00, 0xfb, 0xff], LINE_PIECE), # Line, Cyan
     Piece([0x00, 0x00, 0xff], ELL_PIECE), # L, Blue
     Piece([0xff, 0x9f, 0x00], MIRROR_ELL_PIECE), # mirror L, Orange
     Piece([0xff, 0xff, 0x00], SQUARE_PIECE), # Square, Yellow
     Piece([0x00, 0xff, 0x00], SQUIGLE_PIECE), # Squigle, Green
     Piece([0xff, 0x00, 0xff], TEE_PIECE), # T, Purple
     Piece([0xff, 0x00, 0x00], MIRROR_SQUIGLE_PIECE)] # mirrror Squigle, Red
end

function pieces_amazing()
    [Piece([0xc0, 0xff, 0xee], LINE_PIECE)]
end
