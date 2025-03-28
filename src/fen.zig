const std        = @import("std");
const bitboards  = @import("bitboards.zig");
const Board      = bitboards.Board;
const PieceInfo  = bitboards.PieceInfo;
const Piece      = bitboards.Piece;
const PieceColor = bitboards.PieceColor;

const FenParseError = error { IllegalSymbol };

fn parseFenPositions(fen_string: []const u8) !Board {
    var result = Board.init();

    // FEN strings are declared from left (A) to right (H)
    // starting at the back (A8 [56] -> H8 [63]) and then moving down a
    // row (A7 -> H7) until the final row (A1 [0] -> H1 [7]) is parsed.
    //
    // We will mutate this variable as we insert pieces
    var pos_idx: Board.PositionIndex = 56;

    for (0.., fen_string) |char_idx, char| {
        _ = char_idx;

        // Update the board based on the character
        switch (char) {
            // Numbers depict empty spaces
            '0'...'9' => |n_str| {
                // TODO - Is there an easier way to take the char as a slice of the parent `fen_string`?
                const n = std.fmt.parseInt(u6, &[1]u8{n_str}, 10) catch unreachable;

                unreachable and "All of the position index stuff needs some work, both here and below.";

                // Prevent overflow
                const safe_idx = @as(i16, @intCast(pos_idx)) + n;

                if (@rem(safe_idx + 1, 8) == 0) {
                    // Subtracting 15 moves us to the first file of the previous rank
                    pos_idx -= 15;
                } else {
                    // Otherwise, increment and continue
                    pos_idx = @as(u6, @intCast(safe_idx));
                }

                continue;
            },

            // Characters depict pieces, capitalization denotes team
            'p' => {
                try result.setPieceAtIndex(.pawn, .black, pos_idx);
            },
            'P' => {
                try result.setPieceAtIndex(.pawn, .white, pos_idx);
            },
            'n' => {
                try result.setPieceAtIndex(.knight, .black, pos_idx);
            },
            'N' => {
                try result.setPieceAtIndex(.knight, .white, pos_idx);
            },
            'b' => {
                try result.setPieceAtIndex(.bishop, .black, pos_idx);
            },
            'B' => {
                try result.setPieceAtIndex(.bishop, .white, pos_idx);
            },
            'r' => {
                try result.setPieceAtIndex(.rook, .black, pos_idx);
            },
            'R' => {
                try result.setPieceAtIndex(.rook, .white, pos_idx);
            },
            'q' => {
                try result.setPieceAtIndex(.queen, .black, pos_idx);
            },
            'Q' => {
                try result.setPieceAtIndex(.queen, .white, pos_idx);
            },
            'k' => {
                try result.setPieceAtIndex(.king, .black, pos_idx);
            },
            'K' => {
                try result.setPieceAtIndex(.king, .white, pos_idx);
            },
            '/' => {
                // NOTE - The delimiter is being handled in the code which updates
                //        pos_idx, but I don't know if I like that versus actually
                //        performing the jump in index when we parse.
            },
            ' ' => {
                // TODO
            },
            else => {
                return FenParseError.IllegalSymbol;
            }
        }

        // Update the position index for the next insertion

        if (pos_idx == 7) {
            // This is the last index, final file of first rank.
            // So we're done
            break;
        }

        const safe_idx = @as(i16, @intCast(pos_idx));

        if (@rem(safe_idx + 1, 8) == 0) {
            // Subtracting 15 moves us to the first file of the previous rank
            pos_idx -= 15;
        } else {
            // Otherwise, increment and continue
            pos_idx += 1;
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
    }
}

