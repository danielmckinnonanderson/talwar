const std        = @import("std");
const bitboards  = @import("bitboards.zig");
const Board      = bitboards.Board;
const PieceInfo  = bitboards.PieceInfo;
const Piece      = bitboards.Piece;
const PieceColor = bitboards.PieceColor;

fn parseFenPositions(fen_string: []const u8) !Board {
    var result = Board.init();

    // FEN strings are declared from left (A) to right (H)
    // starting at the back (A8 [56] -> H8 [63]) and then moving down a
    // row (A7 -> H7) until the final row (A1 [0] -> H1 [7]) is parsed.
    //
    // We will mutate this variable as we insert pieces on 
    var pos_idx: Board.PositionIndex = 56;

    const Pair = packed struct {
        pos:   Board.PositionIndex,
        piece: Piece,
        col:   PieceColor,
    };

    var positions: [64]Pair = undefined;

    for (0.., fen_string) |char_idx, char| {
        _ = char_idx;

        switch (char) {
            '0'...'9' => |n| {
                std.fmt.parseInt(u8, n, 10) catch unreachable;
            },
            '/' => |delim| {
                _ = delim;
            },
            'b' => {},
        }

        // switch (state) {
        //     .initial => {
        //         // Nothing to set up, just begin parsing row
        //         state = .{ .parsing_row = .start };
        //     },
        //     .parsing_row => |row_state| {
        //         const char = fen_string[char_idx];

        //         if ((pos_idx + 1) % 8 == 0) {
        //             // Expect a delimiter here
        //         }

        //         switch (row_state) {
        //             // Start of row could be either a piece or an empty indicator
        //             .start => {
        //                 // Check to see if it is an integer indicating blanks
        //                 if (std.fmt.parseInt(u8, char, 10)) |int| {
        //                     // Int is number of empty spaces,
        //                     // advance index by that amount
        //                     char_idx += int;
        //                     state = .{ .parsing_row = .empty };
        //                     continue;

        //                 } else {
        //                     // Not an int, we expect a piece.
        //                     // An error here would be illegal.
        //                     const piece: PieceInfo = try PieceInfo.fromChar(char);
        //                     result.setPieceAt(
        //                         piece.piece,
        //                         piece.color,
        //                         bitboards.Position.intoIndex(char_idx));
        //                     char_idx += 1;
        //                 }
        //             }
        //         }
        //     }
        // }
    }

    // for (0..fen_string.len) |i| {
    //     const char = fen_string[i];
    //     const piece_opt = bitboards.PieceInfo.fromChar(char);
    // }
}

// Test case positions retrieved from https://www.chess.com/terms/fen-chess

test "Parse FEN string (positions section) into bitboard" {
    const Position = bitboards.Position;
    const intoBitboard = Position.intoBitboard;
    {
        const fen = "r1bk3r/p2pBpNp/n4n2/1p1NP2P/6P1/3P4/P1P1K3/q5b1";

        const result = try parseFenPositions(fen);

        // kings
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .D4, .E2 }),
            result.kings);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .E2 }),
            result.kings & result.white);
        try std.testing.expectEqual(
            comptime intoBitboard(&[_]Position{ .D4 }),
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

