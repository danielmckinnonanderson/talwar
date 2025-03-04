const std = @import("std");
const testing = std.testing;

pub const Piece = enum {
    pawn,
    knight,
    bishop,
    rook,
    queen,
    king
};



pub const PieceColor = enum { white, black };

pub const Board = struct {
    /// 8x8 board = 64 squares indexed 0 through 63.
    pub const Position = u6;

    pub const RANK_1: u64 = 0x00000000000000FF;
    pub const RANK_2: u64 = 0x000000000000FF00;
    pub const RANK_3: u64 = 0x0000000000FF0000;
    pub const RANK_4: u64 = 0x00000000FF000000;
    pub const RANK_5: u64 = 0x000000FF00000000;
    pub const RANK_6: u64 = 0x0000FF0000000000;
    pub const RANK_7: u64 = 0x00FF000000000000;
    pub const RANK_8: u64 = 0xFF00000000000000;

    pub const FILE_A: u64 = 0x0101010101010101;
    pub const FILE_B: u64 = 0x0202020202020202;
    pub const FILE_C: u64 = 0x0404040404040404;
    pub const FILE_D: u64 = 0x0808080808080808;
    pub const FILE_E: u64 = 0x1010101010101010;
    pub const FILE_F: u64 = 0x2020202020202020;
    pub const FILE_G: u64 = 0x4040404040404040;
    pub const FILE_H: u64 = 0x8080808080808080;

    white: u64,
    black: u64,

    pawns: u64,
    knights: u64,
    bishops: u64,
    rooks: u64,
    queens: u64,
    kings: u64,

    pub fn init() Board {
        return Board{
            .white   = 0,
            .black   = 0,
            .pawns   = 0,
            .bishops = 0,
            .knights = 0,
            .rooks   = 0,
            .queens  = 0,
            .kings   = 0
        };
    }
};

const PlacementError = error{ PositionOccupied };

/// Place a piece at an empty space.
/// If the space is occupied, raises a `BoardError.PlacementPositionOccupied`.
pub fn placePiece(
    board: *Board,
    piece: Piece,
    color: PieceColor,
    position: Board.Position
) PlacementError!void {
    const pos_bit = @as(u64, 1) << position;
    const occupied = getOccupied(board);

    if ((occupied & pos_bit) != 0) {
        return PlacementError.PositionOccupied;
    }

    switch (piece) {
        .pawn => {
            board.pawns |= pos_bit;
        },
        .knight => {
            board.knights |= pos_bit;
        },
        .bishop => {
            board.bishops |= pos_bit;
        },
        .rook => {
            board.rooks |= pos_bit;
        },
        .queen => {
            board.queens |= pos_bit;
        },
        .king => {
            board.kings |= pos_bit;
        },
    }

    if (color == .black) {
        board.black |= pos_bit;
    } else {
        board.white |= pos_bit;
    }
}

pub fn getOccupied(board: *const Board) u64 {
    return board.white | board.black;
}

pub fn getUnoccupied(board: *const Board) u64 {
    return ~(board.white | board.black);
}

// All piece movements should perform the following steps to end up
// with a u64 representing all legal moves:
//
// 1. Determine if there is actually a piece at the specified position
//    of the correct type. If there is not, raise an error.
// 2. Filter the boards by path type for the piece type in the specified position.
// 3. Continue filtering, now removing spaces occupied by friendly pieces, and stopping
//    pieces which move in a path at the first capture they encounter. Additionally
//    prevent capturing the king at this step.
// 
// TODO - Account for moving into / out of check here.
// TODO - Account for moves which require "move history", like en passant.
//

pub fn getPawnMoves(position: Board.Position, bit_boards: *const Board) anyerror!u64 {
    try std.debug.print("Position: {}\n", .{position});
    _ = bit_boards;
}

pub fn knightMovements(position: Board.Position, bit_boards: *const Board) u64 {
    _ = bit_boards;

    var moves: u64 = 0;
    const board: u64 = @as(u64, 1) << position;
    std.debug.print("Board: {}\n", .{ board });

    // Right 1, Up 2
    moves |= (board << 17) & ~Board.FILE_H;
    // Right 2, Up 1
    moves |= (board << 10) & ~Board.FILE_G & ~Board.FILE_H;
    // Right 2, Down 1
    moves |= (board >>  6) & ~Board.FILE_G & ~Board.FILE_H;
    // Right 1, Down 2
    moves |= (board >> 15) & ~Board.FILE_H;

    // Left 1, Down 2
    moves |= (board >> 17) & ~Board.FILE_A;
    // Left 2, Down 1
    moves |= (board >> 10) & ~Board.FILE_A & ~Board.FILE_B;
    // Left 2, Up 1
    moves |= (board <<  6) & ~Board.FILE_A & ~Board.FILE_B;
    // Left 1, Up 2
    moves |= (board << 15) & ~Board.FILE_A;

    return moves;
}

test "initializing an empty board results in all bits set to zero" {
    const b = Board.init();
    try std.testing.expectEqual(@as(u64, 0), b.white);
    try std.testing.expectEqual(@as(u64, 0), b.black);
    try std.testing.expectEqual(@as(u64, 0), b.pawns);
    try std.testing.expectEqual(@as(u64, 0), b.knights);
    try std.testing.expectEqual(@as(u64, 0), b.bishops);
    try std.testing.expectEqual(@as(u64, 0), b.rooks);
    try std.testing.expectEqual(@as(u64, 0), b.queens);
    try std.testing.expectEqual(@as(u64, 0), b.kings);
}

test "Knight movement from center position (d4)" {
    return error.SkipZigTest;

    // var board = Board.init();
    // 
    // // The center position - d4 is at index 27
    // const center_pos: Board.Position = 27;
    // const moves = knightMovements(center_pos, &board);
    // 
    // // Expected positions for a knight at d4
    // // A knight in the center can move to all 8 possible positions
    // const expected_positions = [8]Board.Position{
    //     10, 12,     // b2, d2 (2 ranks down)
    //     17, 25,     // b3, f3 (1 rank down)
    //     33, 41,     // b5, f5 (1 rank up)
    //     42, 44      // c6, e6 (2 ranks up)
    // };
    // 
    // // Validate that all 8 expected positions are set in the moves bitboard
    // var count: u8 = 0;
    // for (expected_positions) |pos| {
    //     const pos_bit = @as(u64, 1) << pos;
    //     try testing.expect((moves & pos_bit) == pos_bit);
    //     count += 1;
    // }
    // 
    // // Validate that exactly 8 positions are set (no more, no less)
    // // Count bits set to 1 in the moves bitboard
    // var total_bits: u8 = 0;
    // var temp_moves = moves;
    // while (temp_moves != 0) {
    //     total_bits += @as(u8, 1);
    //     temp_moves &= temp_moves - 1; // Clear the least significant bit set
    // }
    // 
    // try testing.expectEqual(count, total_bits);
    // try testing.expectEqual(@as(u8, 8), total_bits);
}

test "`getOccupied` produces the union of bitboards `black` and `white`" {
    var board: Board = Board.init();
    board.white = 0x0F0F0F0F0F0F0F0F;
    board.black = 0xF0F0F0F0F0F0F0F0;
    const actual = getOccupied(&board);

    try std.testing.expectEqual(0xFFFFFFFFFFFFFFFF, actual);
}

test "`getUnoccupied` produces the negation of the union of bitboards `black` and `white`" {
    var board: Board = Board.init();
    board.white = 0x0F0F0F0F0F0F0F0F;
    board.black = 0xF0F0F0F0F0F0F0F0;
    const actual = getUnoccupied(&board);

    try std.testing.expectEqual(0x0000000000000000, actual);
}

test "Pawns can only move forward, or capture diagonally" {
    const board: Board = Board.init();
    _ = board;
}

test "Placing piece on an occupied space raises an error" {
    var board = Board.init();
    const pos: Board.Position = 42;

    // Make the position occupied
    board.black |= (@as(u64, 1) << pos);
    board.kings |= (@as(u64, 1) << pos);

    // This should now raise an error because the pos is occupied
    try std.testing.expectError(
        PlacementError.PositionOccupied,
        placePiece(&board, Piece.pawn, PieceColor.white, pos));

    // White & pawns should both still be empty since we bailed
    try std.testing.expectEqual(0, board.pawns);
    try std.testing.expectEqual(0, board.white);
}

test "Placing piece on an empty space updates the bit-board representations" {
    var board = Board.init();
    const pos: Board.Position = 42;

    try std.testing.expectEqual(0, board.black);
    try std.testing.expectEqual(0, board.queens);

    try placePiece(&board, Piece.queen, PieceColor.black, pos);

    try std.testing.expectEqual(4398046511104, board.black);
    try std.testing.expectEqual(4398046511104, board.queens);
}
