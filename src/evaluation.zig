const std = @import("std");
const bitboards = @import("bitboards.zig");
const Board = bitboards.Board;


pub const Score = f32;

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

    // TODO - Account for some other considerations from
    //        https://www.chessprogramming.org/Material#Other_Material_Considerations
    //        such as mobility (# of possible moves from position), bishop pairs,
    //        and other "greater than sum of parts" piece combos
};

/// Compute the material imbalance of the board, where a positive result
/// indicates that white is ahead and a negative result indicates that black is ahead.
pub fn material(board: *const Board) Centipawns {
    const king_w:   i64 = @popCount(board.white & board.kings);
    const king_b:   i64 = @popCount(board.black & board.kings);
    const queen_w:  i64 = @popCount(board.white & board.queens);
    const queen_b:  i64 = @popCount(board.black & board.queens);
    const rook_w:   i64 = @popCount(board.white & board.rooks);
    const rook_b:   i64 = @popCount(board.black & board.rooks);
    const bishop_w: i64 = @popCount(board.white & board.bishops);
    const bishop_b: i64 = @popCount(board.black & board.bishops);
    const knight_w: i64 = @popCount(board.white & board.knights);
    const knight_b: i64 = @popCount(board.black & board.knights);
    const pawn_w:   i64 = @popCount(board.white & board.pawns);
    const pawn_b:   i64 = @popCount(board.black & board.pawns);

    const kings   = (king_w - king_b)     * CentipawnValues.king;
    const queens  = (queen_w - queen_b)   * CentipawnValues.queen;
    const rooks   = (rook_w - rook_b)     * CentipawnValues.rook;
    const bishops = (bishop_w - bishop_b) * CentipawnValues.bishop;
    const knights = (knight_w - knight_b) * CentipawnValues.knight;
    const pawns   = (pawn_w - pawn_b)     * CentipawnValues.pawn;

    return kings + queens + rooks + bishops + knights + pawns;
}

test "Produce a material score given a board" {
    {
        var board = Board.empty();

        try board.setPieceAtPosition(.king, .black, .E8);
        try std.testing.expectEqual(@as(Centipawns, -10_000), material(&board));

        try board.setPieceAtPosition(.king, .white, .E1);

        try std.testing.expectEqual(@as(Centipawns, 0), material(&board));

        try board.setPieceAtPosition(.bishop, .white, .H5);
        try board.setPieceAtPosition(.knight, .white, .B3);
        try board.setPieceAtPosition(.queen, .white, .A5);

        try std.testing.expectEqual(@as(Centipawns, 1650), material(&board));

        try board.setPieceAtPosition(.pawn, .black, .D6);
        try board.setPieceAtPosition(.rook, .black, .G6);

        try std.testing.expectEqual(@as(Centipawns, 1000), material(&board));
    }
}

