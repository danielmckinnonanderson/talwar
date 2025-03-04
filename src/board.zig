const std = @import("std");
const testing = std.testing;

pub const Board = struct {
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

pub fn getOccupied(board: *const Board) u64 {
    return board.white | board.black;
}

pub fn getUnoccupied(board: *const Board) u64 {
    return ~(board.white | board.black);
}

pub fn getPawnMoves(position: u6, bit_boards: *const Board) anyerror!u64 {
    try std.debug.print("Position: {}\n", .{position});
    _ = bit_boards;
}

pub fn knightMovements(position: u6, bit_boards: *const Board) u64 {
    _ = bit_boards;

    var moves: u64 = 0;
    const board: u64 = @as(u64, 1) << position;
    std.debug.print("Board: {}\n", .{ board });

    // FIXME - This has a bug I think.
    moves |= (board << 17) & ~Board.FILE_A;
    moves |= (board << 10) & ~Board.FILE_A & ~Board.FILE_B;
    moves |= (board >>  6) & ~Board.FILE_A & ~Board.FILE_B;
    moves |= (board >> 15) & ~Board.FILE_A;

    moves |= (board >> 17) & ~Board.FILE_H;
    moves |= (board >> 10) & ~Board.FILE_G & ~Board.FILE_H;
    moves |= (board <<  6) & ~Board.FILE_G & ~Board.FILE_H;
    moves |= (board << 15) & ~Board.FILE_H;

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

test "legal knight movements do not wrap" {
    const b = Board.init();

    // Position A6
    const pos = 40;

    const legal_moves = knightMovements(pos, &b);

    // Bit representation is flipped
    // A B C D E F G H
    //
    // 0 0 0 0 0 0 0 0  1
    // 0 1 0 0 0 0 0 0  2
    // 0 0 1 0 0 0 0 0  3
    // N 0 0 0 0 0 0 0  4
    // 0 0 1 0 0 0 0 0  5
    // 0 1 0 0 0 0 0 0  6
    // 0 0 0 0 0 0 0 0  7
    // 0 0 0 0 0 0 0 0  8

    try std.testing.expectEqual(
        0b00000010_00000100_00000000_00000100_00000010_00000000,
        legal_moves);
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

