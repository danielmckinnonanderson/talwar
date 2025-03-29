const std        = @import("std");
const bitboards  = @import("bitboards.zig");
const Board      = bitboards.Board;
const PieceInfo  = bitboards.PieceInfo;
const Piece      = bitboards.Piece;
const PieceColor = bitboards.PieceColor;

const FenParseError = error { IllegalSymbol, IllegalBlankSpaceValue, UnexpectedDelimiter, };

fn parseFenPositions(fen_string: []const u8) !Board {
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

    for (fen_string) |char| {
        // Update the board based on the character
        switch (char) {
            // Numbers depict empty spaces
            '0'...'8' => |n_str| {
                // TODO - Is there an easier way to take the char as a slice of the parent `fen_string`?
                const n = std.fmt.parseInt(u6, &[1]u8{n_str}, 10) catch {
                    return FenParseError.IllegalBlankSpaceValue;
                };

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

test "Invalid FEN string returns a parse error" {
    {
        const fen = "hello";
        const result = parseFenPositions(fen);

        try std.testing.expectEqual(FenParseError.IllegalSymbol, result);
    }
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

