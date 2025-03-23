const std = @import("std");
const bitboards = @import("bitboards.zig");
const Board = bitboards.Board;


pub const Score = f32;

const PawnScores = struct {
    pub const Pawns = f32;

    pub const king:   Pawns = 200.0;
    pub const queen:  Pawns =   9.0;
    pub const rook:   Pawns =   5.0;
    pub const bishop: Pawns =   3.0;
    pub const knight: Pawns =   3.0;
    pub const pawn:   Pawns =   1.0;

    // Doubled, blocked, and isolated pawns
    pub const dbi: Pawns =   0.5;

    // Number of legal moves
    pub const mobility: Pawns =   0.1;
};

pub const Centipawns = i64;
// Using Turing's valuation table, retrieved from
// https://www.chessprogramming.org/Point_Value#Basic_values
const CentipawnValues = struct {
    pub const king   = 10_000;
    pub const queen  =  1_000;
    pub const rook   =    550;
    pub const bishop =    350;
    pub const knight =    300;
    pub const pawn   =    100;
};

pub fn evaluate(board: *const Board) Score {
    _ = board;
}

pub fn material(board: *const Board) Score {
    const king_w:   i32 = @popCount(board.white & board.kings);
    const king_b:   i32 = @popCount(board.black & board.kings);
    const queen_w:  i32 = @popCount(board.white & board.queens);
    const queen_b:  i32 = @popCount(board.black & board.queens);
    const rook_w:   i32 = @popCount(board.white & board.rooks);
    const rook_b:   i32 = @popCount(board.black & board.rooks);
    const bishop_w: i32 = @popCount(board.white & board.bishops);
    const bishop_b: i32 = @popCount(board.black & board.bishops);
    const knight_w: i32 = @popCount(board.white & board.knights);
    const knight_b: i32 = @popCount(board.black & board.knights);
    const pawn_w:   i32 = @popCount(board.white & board.pawns);
    const pawn_b:   i32 = @popCount(board.black & board.pawns);

    const kings   = (king_w - king_b)     * CentipawnValues.king;
    const queens  = (queen_w - queen_b)   * CentipawnValues.queen;
    const rooks   = (rook_w - rook_b)     * CentipawnValues.rook;
    const bishops = (bishop_w - bishop_b) * CentipawnValues.bishop;
    const knights = (knight_w - knight_b) * CentipawnValues.knight;
    const pawns   = (pawn_w - pawn_b)     * CentipawnValues.pawn;

    return kings + queens + rooks + bishops + knights + pawns;
}

test "Produce a material score given a board" {
    try std.testing.expect(false and "FIXME tomorrow!");
}

