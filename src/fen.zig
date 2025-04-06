const std         = @import("std");
const bitboards   = @import("bitboards.zig");
const Board       = bitboards.Board;
const CastleState = bitboards.CastleState;
const PieceInfo   = bitboards.PieceInfo;
const Piece       = bitboards.Piece;
const PieceColor  = bitboards.PieceColor;


const FenParseError = error {
    IllegalSymbol,
    IllegalBlankSpaceValue,
    UnexpectedDelimiter,
    InvalidPosition,
};

/// Given a FEN string in the format
/// `"<piece positions> <team to move> <castling rights> <en passant captures> <halfmoves> <fullmoves>"`,
/// return a `Board` which models the game state specified by the FEN string.
pub fn parseFen(fen_string: []const u8) !Board {
    const parts = std.mem.splitScalar(u8, fen_string.*, ' ');

    var board        = try parseFenPositions(parts[0]);
    const to_move    = try parseFenToMove(parts[1]);
    const can_castle = try parseFenCastle(parts[2]);
    const en_passant = try parseFenEnPassant(parts[3]);
    const halfmoves  = try parseFenHalfmoves(parts[4]);
    const fullmoves  = try parseFenFullmoves(parts[5]);

    board.castle = can_castle;

    _ = .{ board, to_move, can_castle, en_passant, halfmoves, fullmoves };
}

fn parseFenEnPassant(fen_part: []const u8) !u64 {
    var rank: u64 = 0;
    var file: u64 = 0;

    if (!(fen_part.len == 1 or fen_part.len == 2)) {
        return FenParseError.InvalidPosition;
    }

    for (fen_part) |char| {
        switch (char) {
            '-' => return 0,

            'a', 'A' => file = Board.FILE_A,
            'b', 'B' => file = Board.FILE_B,
            'c', 'C' => file = Board.FILE_C,
            'd', 'D' => file = Board.FILE_D,
            'e', 'E' => file = Board.FILE_E,
            'f', 'F' => file = Board.FILE_F,
            'g', 'G' => file = Board.FILE_G,
            'h', 'H' => file = Board.FILE_H,

            '1'      => rank = Board.RANK_1,
            '2'      => rank = Board.RANK_2,
            '3'      => rank = Board.RANK_3,
            '4'      => rank = Board.RANK_4,
            '5'      => rank = Board.RANK_5,
            '6'      => rank = Board.RANK_6,
            '7'      => rank = Board.RANK_7,
            '8'      => rank = Board.RANK_8,

            else => return FenParseError.IllegalSymbol,
        }
    }

    if (rank == 0 or file == 0) {
        return FenParseError.InvalidPosition;
    }

    return rank & file;
}

fn parseFenCastle(fen_part: []const u8) !CastleState {
    var result = CastleState.ZERO;

    if (fen_part.len == 1 and fen_part[0] == '-') {
        return CastleState.ZERO;
    }

    for (fen_part) |char| {
        switch (char) {
            'k' => result.black_k = 1,
            'q' => result.black_q = 1,
            'K' => result.white_k = 1,
            'Q' => result.white_q = 1,
            else => return FenParseError.IllegalSymbol,
        }
    }

    return result;
}

fn parseFenHalfmoves(fen_part: []const u8) !u16 {
    return parseFenUnsignedInteger(fen_part);
}

fn parseFenFullmoves(fen_part: []const u8) !u16 {
    return parseFenUnsignedInteger(fen_part);
}

inline fn parseFenUnsignedInteger(fen_part: []const u8) !u16 {
    return std.fmt.parseInt(u16, fen_part, 10) catch {
        return FenParseError.IllegalSymbol;
    };
}

fn parseFenToMove(fen_part: []const u8) !PieceColor {
    if (fen_part.len != 1) {
        return FenParseError.IllegalSymbol;
    }

    const char = fen_part[0];

    return switch (char) {
        'b' => .black,
        'w' => .white,
        else => FenParseError.IllegalSymbol,
    };
}

fn parseFenPositions(fen_part: []const u8) !Board {
    var result = Board.empty();

    // FEN strings are declared from left (A) to right (H)
    // starting at the back (A8 [56] -> H8 [63]) and then moving down a
    // row (A7 -> H7) until the final row (A1 [0] -> H1 [7]) is parsed.
    //
    // We will mutate this variable as we insert pieces.
    //
    // Even though valid values will fit within a u6, we will keep
    // this value as a signed integer with a larger size in order to catch
    // runtime overflows and underflows from invalid input.
    var pos_idx: i16 = 56;

    for (fen_part) |char| {
        // Update the board based on the character
        switch (char) {
            // Numbers depict empty spaces
            '0'...'8' => |n_str| {
                // TODO - Is there an easier way to take the char as a slice of the parent `fen_part`?
                const n = std.fmt.parseInt(u6, &[1]u8{n_str}, 10) catch {
                    return FenParseError.IllegalBlankSpaceValue;
                };

                // TODO - Check to see that the numbers here are actually legal.
                //        Current implementation does not prevent a line like "6k6".
                pos_idx += n;
                continue;
            },

            // Characters depict pieces, capitalization denotes team
            'p' => {
                try result.setPieceAtIndex(.pawn, .black, @intCast(pos_idx));
                pos_idx += 1;
            },
            'P' => {
                try result.setPieceAtIndex(.pawn, .white, @intCast(pos_idx));
                pos_idx += 1;
            },
            'n' => {
                try result.setPieceAtIndex(.knight, .black, @intCast(pos_idx));
                pos_idx += 1;
            },
            'N' => {
                try result.setPieceAtIndex(.knight, .white, @intCast(pos_idx));
                pos_idx += 1;
            },
            'b' => {
                try result.setPieceAtIndex(.bishop, .black, @intCast(pos_idx));
                pos_idx += 1;
            },
            'B' => {
                try result.setPieceAtIndex(.bishop, .white, @intCast(pos_idx));
                pos_idx += 1;
            },
            'r' => {
                try result.setPieceAtIndex(.rook, .black, @intCast(pos_idx));
                pos_idx += 1;
            },
            'R' => {
                try result.setPieceAtIndex(.rook, .white, @intCast(pos_idx));
                pos_idx += 1;
            },
            'q' => {
                try result.setPieceAtIndex(.queen, .black, @intCast(pos_idx));
                pos_idx += 1;
            },
            'Q' => {
                try result.setPieceAtIndex(.queen, .white, @intCast(pos_idx));
                pos_idx += 1;
            },
            'k' => {
                try result.setPieceAtIndex(.king, .black, @intCast(pos_idx));
                pos_idx += 1;
            },
            'K' => {
                try result.setPieceAtIndex(.king, .white, @intCast(pos_idx));
                pos_idx += 1;
            },
            '/' => {
                if (@mod(pos_idx, 8) != 0) {
                    return FenParseError.UnexpectedDelimiter;
                }

                pos_idx -= 16;
                continue;

            },
            ' ' => {
                break;
            },
            else => |value| {
                std.debug.print("Found illegal symbol in FEN string: {c}\n", .{value});
                return FenParseError.IllegalSymbol;
            }
        }
    }

    return result;
}

test "Illegal symbol in FEN string returns a parse error" {
    const fen = "hello";
    const result = parseFenPositions(fen);

    try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
}

// FIXME
test "Invalid spaces-per-row in FEN string returns a parse error" {
    const fen = "8/6k6/8/8/8/8/8/K7";
    _ = fen;

    // try std.testing.expectEqual(FenParseError.UnexpectedDelimiter, result);
}

test "Illegal delimiter in FEN string returns a parse error" {
    const fen = "5/8/8/k7/8/8/8/K7";
    const result = parseFenPositions(fen);

    try std.testing.expectEqual(FenParseError.UnexpectedDelimiter, result);
}

test "Parse FEN string (positions section) into bitboard" {
    // Test case positions retrieved from https://www.chess.com/terms/fen-chess

    const Position = bitboards.Position;
    const intoBitboard = Position.intoBitboard;
    {
        const fen = "3k4/8/8/8/8/8/4K3/8";

        const result = try parseFenPositions(fen);


        // kings
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .D8, .E2 }),
            result.kings);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .E2 }),
            result.kings & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .D8 }),
            result.kings & result.black);
    }

    {
        const fen = "r1bk3r/p2pBpNp/n4n2/1p1NP2P/6P1/3P4/P1P1K3/q5b1";

        const result = try parseFenPositions(fen);

        // kings
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .D8, .E2 }),
            result.kings);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .E2 }),
            result.kings & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .D8 }),
            result.kings & result.black);
        
        // rooks
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A8, .H8 }),
            result.rooks);
        try std.testing.expectEqual(
            0,
            result.rooks & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A8, .H8 }),
            result.rooks & result.black);

        // bishops
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .C8, .E7, .G1 }),
            result.bishops);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .E7 }),
            result.bishops & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .C8, .G1 }),
            result.bishops & result.black);

        // queens
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A1 }),
            result.queens);
        try std.testing.expectEqual(
            0,
            result.queens & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A1 }),
            result.queens & result.black);

        // knights
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .G7, .A6, .F6, .D5 }),
            result.knights);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .G7, .D5 }),
            result.knights & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A6, .F6 }),
            result.knights & result.black);

        // pawns
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A2, .A7, .B5, .C2, .D3, .D7, .E5, .F7, .G4, .H5, .H7 }),
            result.pawns);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A2, .C2, .D3, .E5, .G4, .H5 }),
            result.pawns & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .A7, .B5, .D7, .F7, .H7 }),
            result.pawns & result.black);
    }
}

test "Parsing en passant from a FEN string results in correct space" {
    const intoBitboard = bitboards.Position.intoBitboard;
    {
        const fen = "A1";

        const result = try parseFenEnPassant(fen);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]bitboards.Position{ .A1 }), result);
    }

    {
        const fen = "e3";

        const result = try parseFenEnPassant(fen);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]bitboards.Position{ .E3 }), result);
    }

    {
        const fen = "-";

        const result = try parseFenEnPassant(fen);
        try std.testing.expectEqual(0, result);
    }
}

test "Produce an error when en passant section is invalid" {
    {
        const fen = "waytoolong";

        const result = parseFenEnPassant(fen);
        try std.testing.expectEqual(FenParseError.InvalidPosition, result);
    }

    {
        const fen = "z9";

        const result = parseFenEnPassant(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }
}

test "Parsing team to move from a FEN string results in correct value" {
    {
        const fen = "b";

        const result = parseFenToMove(fen);
        try std.testing.expectEqual(.black, result);
    }

    {
        const fen = "w";

        const result = parseFenToMove(fen);
        try std.testing.expectEqual(.white, result);
    }
}

test "Produce an error when team to move section is invalid" {
    {
        const fen = "z";

        const result = parseFenToMove(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }

    {
        const fen = "toolong";

        const result = parseFenToMove(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }
}

test "Parsing number of full moves results in correct value" {
    {
        const fen = "72";

        const result = parseFenFullmoves(fen);
        try std.testing.expectEqual(72, result);
    }

    {
        const fen = "-7251";

        const result = parseFenFullmoves(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }

    {
        const fen = "NaN";

        const result = parseFenFullmoves(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }
}


test "Parsing number of half moves results in correct value" {
    {
        const fen = "72";

        const result = parseFenHalfmoves(fen);
        try std.testing.expectEqual(72, result);
    }

    {
        const fen = "-7251";

        const result = parseFenHalfmoves(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }

    {
        const fen = "NaN";

        const result = parseFenHalfmoves(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }
}

test "Parsing castle availability results in correct state" {
    {
        const fen = "-";

        const result = parseFenCastle(fen);
        try std.testing.expectEqual(CastleState.ZERO, result);
    }

    {
        const fen = "kqKQ";

        const result = parseFenCastle(fen);
        try std.testing.expectEqual(CastleState {
                .white_k = 1,
                .white_q = 1,
                .black_k = 1,
                .black_q = 1
            },
            result);
    }

    {
        const fen = "kQ";

        const result = parseFenCastle(fen);
        try std.testing.expectEqual(CastleState {
                .white_k = 0,
                .white_q = 1,
                .black_k = 1,
                .black_q = 0
            },
            result);
    }

    {
        const fen = "kQ-";

        const result = parseFenCastle(fen);
        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }
}

