const std = @import("std");

pub const Piece = enum {
    pawn,
    knight,
    bishop,
    rook,
    queen,
    king
};

pub const PieceColor = enum { white, black };

pub const Position = enum {
    A1, A2, A3, A4, A5, A6, A7, A8,
    B1, B2, B3, B4, B5, B6, B7, B8,
    C1, C2, C3, C4, C5, C6, C7, C8,
    D1, D2, D3, D4, D5, D6, D7, D8,
    E1, E2, E3, E4, E5, E6, E7, E8,
    F1, F2, F3, F4, F5, F6, F7, F8,
    G1, G2, G3, G4, G5, G6, G7, G8,
    H1, H2, H3, H4, H5, H6, H7, H8,

    pub fn intoIndex(position: Position) Board.PositionIndex {
        return switch (position) {
            .A1 => 0, .A2 =>  8, .A3 => 16, .A4 => 24, .A5 => 32, .A6 => 40, .A7 => 48, .A8 => 56,
            .B1 => 1, .B2 =>  9, .B3 => 17, .B4 => 25, .B5 => 33, .B6 => 41, .B7 => 49, .B8 => 57,
            .C1 => 2, .C2 => 10, .C3 => 18, .C4 => 26, .C5 => 34, .C6 => 42, .C7 => 50, .C8 => 58,
            .D1 => 3, .D2 => 11, .D3 => 19, .D4 => 27, .D5 => 35, .D6 => 43, .D7 => 51, .D8 => 59,
            .E1 => 4, .E2 => 12, .E3 => 20, .E4 => 28, .E5 => 36, .E6 => 44, .E7 => 52, .E8 => 60,
            .F1 => 5, .F2 => 13, .F3 => 21, .F4 => 29, .F5 => 37, .F6 => 45, .F7 => 53, .F8 => 61,
            .G1 => 6, .G2 => 14, .G3 => 22, .G4 => 30, .G5 => 38, .G6 => 46, .G7 => 54, .G8 => 62,
            .H1 => 7, .H2 => 15, .H3 => 23, .H4 => 31, .H5 => 39, .H6 => 47, .H7 => 55, .H8 => 63,
        };
    }

    pub fn intoBitboard(positions: []const Position) u64 {
        var bitboard: u64 = 0;
        
        for (positions) |position| {
            bitboard |= @as(u64, 1) << Position.intoIndex(position);
        }

        return bitboard;
    }
};

pub const PieceInfo = struct {
    color: PieceColor,
    piece: Piece,
};

pub const Board = struct {
    /// 8x8 board = 64 squares indexed 0 through 63.
    pub const PositionIndex = u6;

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

    attacked_by_white: u64,
    attacked_by_black: u64,

    pawns: u64,
    knights: u64,
    bishops: u64,
    rooks: u64,
    queens: u64,
    kings: u64,

    pub fn empty() Board {
        return Board {
            .white   = 0,
            .attacked_by_white = 0,
            .black   = 0,
            .attacked_by_black = 0,
            .pawns   = 0,
            .bishops = 0,
            .knights = 0,
            .rooks   = 0,
            .queens  = 0,
            .kings   = 0,
        };
    }

    pub fn init() Board {
        var board = Board {
            .white   = comptime Position.intoBitboard(
                        &[_]Position{ .A1, .B1, .C1, .D1, .E1, .F1, .G1, .H1,
                                      .A2, .B2, .C2, .D2, .E2, .F2, .G2, .H2 }),
            .attacked_by_white = comptime Position.intoBitboard(
                        &[_]Position{ .B1, .C1, .D1, .E1, .F1, .G1,
                                      .A2, .B2, .C2, .D2, .E2, .F2, .G2, .H2,
                                      .A3, .B3, .C3, .D3, .E3, .F3, .G3, .H3, }),
            .black   = comptime Position.intoBitboard(
                        &[_]Position{ .A7, .B7, .C7, .D7, .E7, .F7, .G7, .H7,
                                      .A8, .B8, .C8, .D8, .E8, .F8, .G8, .H8 }),
            .attacked_by_black = comptime Position.intoBitboard(
                        &[_]Position{ .B8, .C8, .D8, .E8, .F8, .G8,
                                      .A7, .B7, .C7, .D7, .E7, .F7, .G7, .H7,
                                      .A6, .B6, .C6, .D6, .E6, .F6, .G6, .H6, }),
            .pawns   = comptime Position.intoBitboard(
                        &[_]Position{ .A2, .B2, .C2, .D2, .E2, .F2, .G2, .H2,
                                      .A7, .B7, .C7, .D7, .E7, .F7, .G7, .H7 }),
            .bishops = comptime Position.intoBitboard(&[_]Position{ .C1, .F1, .C8, .F8 }),
            .knights = comptime Position.intoBitboard(&[_]Position{ .B1, .G1, .B8, .G8 }),
            .rooks   = comptime Position.intoBitboard(&[_]Position{ .A1, .H1, .A8, .H8 }),
            .queens  = comptime Position.intoBitboard(&[_]Position{ .D1, .D8 }),
            .kings   = comptime Position.intoBitboard(&[_]Position{ .E1, .E8 }),
        };

        board.attacked_by_white = attackMask(.white, &board);
        board.attacked_by_black = attackMask(.black, &board);

        return board;
    }

    pub inline fn occupied(self: *const Board) u64 {
        return self.white | self.black;
    }

    pub inline fn unoccupied(self: *const Board) u64 {
        return ~(self.white | self.black);
    }

    pub const GetPieceError = error { PositionUnoccupied };

    pub fn getPieceAt(self: *const Board, position: Position) GetPieceError!PieceInfo {
        const pos_bits = @as(u64, 1) << Position.intoIndex(position);
        
        const color = if (self.white & pos_bits != 0)
            PieceColor.white
        else if (self.black & pos_bits != 0)
            PieceColor.black
        else
            return GetPieceError.PositionUnoccupied;
        
        const piece = if (self.pawns & pos_bits != 0)
            Piece.pawn
        else if (self.knights & pos_bits != 0)
            Piece.knight
        else if (self.bishops & pos_bits != 0)
            Piece.bishop
        else if (self.rooks & pos_bits != 0)
            Piece.rook
        else if (self.queens & pos_bits != 0)
            Piece.queen
        else if (self.kings & pos_bits != 0)
            Piece.king
        else {
            std.debug.assert(false and "Occupied square had no piece type present. This is quite bad.");
            unreachable;
        };

        
        return .{ .piece = piece, .color = color };
    }

    pub fn setPieceAt(
        self: *Board,
        piece: Piece,
        color: PieceColor,
        position: Position,
    ) void {
        const pos_bit = @as(u64, 1) << Position.intoIndex(position);

        switch (piece) {
            .pawn   => self.pawns   |= pos_bit,
            .knight => self.knights |= pos_bit,
            .bishop => self.bishops |= pos_bit,
            .rook   => self.rooks   |= pos_bit,
            .queen  => self.queens  |= pos_bit,
            .king   => self.kings   |= pos_bit,
        }


        if (color == .black) {
            self.black |= pos_bit;
            self.attacked_by_black = attackMask(.black, self);
        } else {
            self.white |= pos_bit;
            self.attacked_by_white = attackMask(.white, self);
        }
    }

    const RemovePieceError = error { PositionUnoccupied };

    pub fn removePieceAt(self: *Board, position: Position) !void {
        const present = self.getPieceAt(position) catch {
            return RemovePieceError.PositionUnoccupied;
        };

        const pos_bits = @as(u64, 1) << Position.intoIndex(position);

        if (present.color == .white) {
            self.white &= ~pos_bits;
        } else {
            self.black &= ~pos_bits;
        }

        switch (present.piece) {
            .pawn   => self.pawns   &= ~pos_bits,
            .knight => self.knights &= ~pos_bits,
            .bishop => self.bishops &= ~pos_bits,
            .rook   => self.rooks   &= ~pos_bits,
            .queen  => self.queens  &= ~pos_bits,
            .king   => self.kings   &= ~pos_bits,
        }

        self.attacked_by_white = attackMask(.white, self);
        self.attacked_by_black = attackMask(.black, self);
    }

    pub const ApplyMoveError = error {
        OriginUnoccupied,
        IllegalMove,
        MoveIntoCheck
    };

    // TODO - Account for castling
    pub fn applyMove(self: *Board, from: Position, to: Position) ApplyMoveError!void {
        const piece_info: PieceInfo = self.getPieceAt(from) catch {
            return ApplyMoveError.OriginUnoccupied;
        };

        const origin_idx = Position.intoIndex(from);
        const dest_bits = Position.intoBitboard(&[1]Position{ to });

        const moves = switch (piece_info.piece) {
            .pawn   => pawnMovementMask(origin_idx, self),
            .knight => knightMovementMask(origin_idx, self),
            .bishop => bishopMovementMask(origin_idx, self),
            .rook   => rookMovementMask(origin_idx, self),
            .queen  => queenMovementMask(origin_idx, self),
            .king   => kingMovementMask(origin_idx, self),
        };

        // If we have nowhere to move to before we even begin filtering,
        // or if the desired destination is not a legal move,
        // then the provided destination is illegal no matter what.
        if (moves == 0 or (moves & dest_bits) == 0) {
            return ApplyMoveError.IllegalMove;
        }

        if ((moves & dest_bits) == 0) {
            return ApplyMoveError.IllegalMove;
        }

        // Copy the board and speculatively apply the move to it
        var speculative: Board = self.*;

        // Remove the piece at `from` and place it at `to`.
        // We also expect `setPieceAt` to recalculate the `attack_by` mask.
        speculative.removePieceAt(from) catch unreachable;

        // If there is a piece present it will be removed, and if there
        // isn't a piece present we don't care (thus we discard the error)
        speculative.removePieceAt(to) catch {};

        speculative.setPieceAt(piece_info.piece, piece_info.color, to);

        // Finally, check if our own king is in check
        const op_attacks = if (piece_info.color == .white) speculative.attacked_by_black
            else speculative.attacked_by_white;

        const allies = if (piece_info.color == .white) speculative.white else speculative.black;

        if ((allies & speculative.kings) & op_attacks != 0) {
            return ApplyMoveError.MoveIntoCheck;
        }

        // Otherwise, this is a legal move that does not put us into check.
        // Persist the move by ending speculation.
        self.* = speculative;
    }

    /// Implements the format interface for the board as whole, writing the
    /// pieces / colors to a visual representation
    pub fn format(
        self: Board,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.writeAll("  +-----------------+\n");

        var rank: usize = 7;

        while (true) : (rank -%= 1) {
            try writer.print("{d} | ", .{rank + 1});

            var file: usize = 0;
            while (file < 8) : (file += 1) {
                const position = (rank * 8) + file;
                const bit_position: u64 = @as(u64, 1) << @intCast(position);
                
                const is_white = (self.white & bit_position) != 0;
                const is_black = (self.black & bit_position) != 0;
                
                if (!is_white and !is_black) {
                    try writer.writeAll(". ");
                    continue;
                }
                
                var piece_char: u8 = '.';
                
                if (self.pawns & bit_position != 0) {
                    piece_char = 'P';
                } else if (self.knights & bit_position != 0) {
                    piece_char = 'N';
                } else if (self.bishops & bit_position != 0) {
                    piece_char = 'B';
                } else if (self.rooks & bit_position != 0) {
                    piece_char = 'R';
                } else if (self.queens & bit_position != 0) {
                    piece_char = 'Q';
                } else if (self.kings & bit_position != 0) {
                    piece_char = 'K';
                }
                
                // Use lowercase for black pieces
                if (is_black) {
                    piece_char = std.ascii.toLower(piece_char);
                }
                
                try writer.print("{c} ", .{piece_char});
            }

            try writer.writeAll("|\n");
            
            if (rank == 0) break;
        }

        try writer.writeAll("  +-----------------+\n");
        try writer.writeAll("    A B C D E F G H  \n");
    }

    /// Prints a bitboard in a chess board format with '.' for empty squares and 'x' for occupied squares
    pub fn printBitboard(bitboard: u64) void {
        const stdout = std.io.getStdOut().writer();

        stdout.writeAll("  +-----------------+\n") catch {};

        var rank: usize = 7;
        while (true) : (rank -%= 1) {
            stdout.print("{d} | ", .{rank + 1}) catch {};

            var file: usize = 0;
            while (file < 8) : (file += 1) {
                const position = (rank * 8) + file;
                const bit = @as(u64, 1) << @intCast(position);

                if (bitboard & bit != 0) {
                    stdout.writeAll("x ") catch {};
                } else {
                    stdout.writeAll(". ") catch {};
                }
            }

            stdout.writeAll("|\n") catch {};

            if (rank == 0) break;
        }

        stdout.writeAll("  +-----------------+\n") catch {};
        stdout.writeAll("    A B C D E F G H  \n") catch {};
    }

};

const PlacementError = error{ PositionOccupied };

fn attackedByPawns(pawn_positions: u64, color: PieceColor) u64 {
    var attacked_squares: u64 = 0;
    var remaining_positions = pawn_positions;

    while (remaining_positions != 0) {
        const lsb = remaining_positions & (~remaining_positions + 1);
        // Count trailing zeros gives us the position
        const position = @ctz(lsb);
        const attacks_from_position = attackedByPawn(@intCast(position), color);
        attacked_squares |= attacks_from_position;

        remaining_positions &= ~lsb;
    }

    return attacked_squares;
}

/// Given a position, return a bitboard that shows the squares that a pawn present in that
/// position of the specified color would threaten.
fn attackedByPawn(position: Board.PositionIndex, color: PieceColor) u64 {
    const pos_bit = @as(u64, 1) << position;

    const at_final_rank: bool = if (color == .white)
        pos_bit & Board.RANK_8 != 0
    else
        pos_bit & Board.RANK_1 != 0;

    if (at_final_rank) {
        return 0;
    }

    const on_a_file = (pos_bit & Board.FILE_A) != 0;
    const on_h_file = (pos_bit & Board.FILE_H) != 0;

    var attacks: u64 = 0;

    if (color == .white) {
        if (!on_h_file) {
            attacks |= @as(u64, 1) << (position + 9);
        }

        if (!on_a_file) {
            attacks |= @as(u64, 1) << (position + 7);
        }
    } else {
        if (!on_h_file) {
            attacks |= @as(u64, 1) << (position - 7);
        }

        if (!on_a_file) {
            attacks |= @as(u64, 1) << (position - 9);
        }
    }

    return attacks;
}

fn attackedByRooks(rook_positions: u64, board: *const Board) u64 {
    var attacked_squares: u64 = 0;
    var remaining_positions = rook_positions;

    while (remaining_positions != 0) {
        const lsb = remaining_positions & (~remaining_positions + 1);
        // Count trailing zeros gives us the position
        const position = @ctz(lsb);
        const attacks_from_position = attackedByRook(@intCast(position), board);
        attacked_squares |= attacks_from_position;

        remaining_positions &= ~lsb;
    }

    return attacked_squares;
}

fn attackedByRook(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit = @as(u64, 1) << position;

    std.debug.assert((board.occupied() & pos_bit) != 0);

    var attacking: u64 = 0;

    // TODO - There's definitely a way to unroll these loops and make this a bit tighter.
    //        Same goes for the other rook method, maybe for the bishop ones too.

    // up
    var current_pos: Board.PositionIndex = position;
    while (current_pos < 56) {
        current_pos += 8;
        const current_bit = @as(u64, 1) << current_pos;

        attacking |= current_bit;

        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }

    // down
    current_pos = position;
    while (current_pos >= 8) {
        current_pos -= 8;
        const current_bit = @as(u64, 1) << current_pos;

        attacking |= current_bit;

        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }

    // right
    const file = position % 8;
    current_pos = position;
    while (file < 7 and current_pos % 8 < 7) {
        current_pos += 1;
        const current_bit = @as(u64, 1) << current_pos;

        attacking |= current_bit;

        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }

    // left
    current_pos = position;
    while (file > 0 and current_pos % 8 > 0) {
        current_pos -= 1;
        const current_bit = @as(u64, 1) << current_pos;

        attacking |= current_bit;

        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }

    return attacking;
}

fn attackedByBishop(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit = @as(u64, 1) << position;
    var moves: u64 = 0;

    // top left
    var current_pos = position;

    if (!(pos_bit & Board.RANK_8 != 0 or pos_bit & Board.FILE_A != 0)) {
        while (current_pos <= 62) {
            current_pos += 7;
            const current_bit = @as(u64, 1) << @intCast(current_pos);

            moves |= current_bit;

            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer overflow
            if ((current_bit & Board.RANK_8) != 0 or (current_bit & Board.FILE_A) != 0) {
                break;
            }
        }
    }

    // top right
    current_pos = position;

    if (!(pos_bit & Board.RANK_8 != 0 or pos_bit & Board.FILE_H != 0)) {
        while (current_pos <= 63) {
            current_pos += 9;
            const current_bit = @as(u64, 1) << @intCast(current_pos);
            
            moves |= current_bit;
            
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer overflow
            if ((current_bit & Board.RANK_8) != 0 or (current_bit & Board.FILE_H) != 0) {
                break;
            }
        }
    }

    // Bottom-right
    current_pos = position;

    if (!(pos_bit & Board.RANK_1 != 0 or pos_bit & Board.FILE_H != 0)) {
        while (current_pos >= 1) {
            current_pos -= 7;
            const current_bit = @as(u64, 1) << @intCast(current_pos);
            
            moves |= current_bit;
            
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer underflow
            if ((current_bit & Board.RANK_1) != 0 or (current_bit & Board.FILE_H) != 0) {
                break;
            }
        }
    }
    
    // Bottom-left
    current_pos = position;

    if (!(pos_bit & Board.RANK_1 != 0 or pos_bit & Board.FILE_A != 0)) {
        while (current_pos >= 0) {
            current_pos -= 9;
            const current_bit = @as(u64, 1) << @intCast(current_pos);
            
            moves |= current_bit;
            
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer underflow
            if ((current_bit & Board.RANK_1) != 0 or (current_bit & Board.FILE_A) != 0) {
                break;
            }
        }
    }

    return moves;
}

fn attackedByKnight(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit: u64 = @as(u64, 1) << position;

    // Rather than return an error, let's just say this state is completely illegal and crash.
    std.debug.assert((board.occupied() & pos_bit) != 0);

    const not_a_file  = ~Board.FILE_A;
    const not_ab_file = ~(Board.FILE_A | Board.FILE_B);
    const not_h_file  = ~Board.FILE_H;
    const not_gh_file = ~(Board.FILE_G | Board.FILE_H);

    var moves: u64 = 0;

    // North movements (up 2, then left or right 1)
    moves |= (pos_bit << 15) & not_h_file;
    moves |= (pos_bit << 17) & not_a_file;

    // South movements (down 2, then left or right 1)
    moves |= (pos_bit >> 15) & not_a_file;
    moves |= (pos_bit >> 17) & not_h_file;

    // East movements (right 2, then up or down 1)
    moves |= (pos_bit << 10) & not_ab_file;
    moves |= (pos_bit >>  6) & not_ab_file;

    // West movements (left 2, then up or down 1)
    moves |= (pos_bit <<  6) & not_gh_file;
    moves |= (pos_bit >> 10) & not_gh_file;

    return moves;
}

fn attackedByKnights(knight_positions: u64, board: *const Board) u64 {
    var attacked_squares: u64 = 0;
    var remaining_positions = knight_positions;

    while (remaining_positions != 0) {
        const lsb = remaining_positions & (~remaining_positions + 1);
        // Count trailing zeros gives us the position
        const position = @ctz(lsb);
        const attacks_from_position = attackedByKnight(@intCast(position), board);
        attacked_squares |= attacks_from_position;

        remaining_positions &= ~lsb;
    }

    return attacked_squares;
}

fn attackedByBishops(bishop_positions: u64, board: *const Board) u64 {
    var attacked_squares: u64 = 0;
    var remaining_positions = bishop_positions;

    while (remaining_positions != 0) {
        const lsb = remaining_positions & (~remaining_positions + 1);
        // Count trailing zeros gives us the position
        const position = @ctz(lsb);
        const attacks_from_position = attackedByBishop(@intCast(position), board);
        attacked_squares |= attacks_from_position;

        remaining_positions &= ~lsb;
    }

    return attacked_squares;
}

fn attackedByQueen(position: Board.PositionIndex, board: *const Board) u64 {
    return attackedByBishop(position, board) | attackedByRook(position, board);
}

fn attackedByQueens(queen_positions: u64, board: *const Board) u64 {
    return attackedByBishops(queen_positions, board) | attackedByRooks(queen_positions, board);
}

fn attackedByKing(position: Board.PositionIndex, board: *const Board) u64 {
    const king_bitboard: u64 = @as(u64, 1) << position;

    // There better be a king here.
    std.debug.assert(board.occupied() & king_bitboard != 0);

    // Prevent wrapping around the board
    const not_a_file = ~Board.FILE_A;
    const not_h_file = ~Board.FILE_H;

    var moves: u64 = 0;

    // North, North-East, East
    moves |= (king_bitboard << 8);
    moves |= (king_bitboard << 9) & not_a_file;
    moves |= (king_bitboard << 1) & not_a_file;

    // South-East, South, South-West
    moves |= (king_bitboard >> 7) & not_a_file;
    moves |= (king_bitboard >> 8);
    moves |= (king_bitboard >> 9) & not_h_file;

    // West, North-West
    moves |= (king_bitboard >> 1) & not_h_file;
    moves |= (king_bitboard << 7) & not_h_file;


    return moves;
}

fn attackedByKings(king_positions: u64, board: *const Board) u64 {
    var attacked_squares: u64 = 0;
    var remaining_positions = king_positions;

    while (remaining_positions != 0) {
        const lsb = remaining_positions & (~remaining_positions + 1);
        // Count trailing zeros gives us the position
        const position = @ctz(lsb);
        const attacks_from_position = attackedByKing(@intCast(position), board);
        attacked_squares |= attacks_from_position;

        remaining_positions &= ~lsb;
    }

    return attacked_squares;
}

pub fn attackMask(color: PieceColor, board: *const Board) u64 {
    const team = if (color == .white) board.white else board.black;

    const kings   = attackedByKings(team & board.kings, board);
    const queens  = attackedByQueens(team & board.queens, board);
    const rooks   = attackedByRooks(team & board.rooks, board);
    const bishops = attackedByBishops(team & board.bishops, board);
    const knights = attackedByKnights(team & board.knights, board);
    const pawns   = attackedByPawns(team & board.pawns, color);

    return kings | queens | rooks | bishops | knights | pawns;
}


// TODO - Account for en passant
pub fn pawnMovementMask(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit: u64 = @as(u64, 1) << position;

    var moves: u64 = 0;

    std.debug.assert((board.occupied() & pos_bit) != 0);

    const color: PieceColor = if ((board.white & pos_bit) != 0)
        PieceColor.white
    else
        PieceColor.black;

    const at_final_rank: bool = if (color == .white)
        pos_bit & Board.RANK_8 != 0
    else
        pos_bit & Board.RANK_1 != 0;

    if (at_final_rank) {
        // If we can't move forward there are no legal moves for us to make.
        // We're done here.
        return 0;
    }

    // Otherwise, we know we have some room to work.

    // Simple case, one square forward (forward being color-dependent).
    const one_fwd_sq: u6 = if (color == .white) 
        position + 8
    else
        position - 8;

    const one_fwd_pos = @as(u64, 1) << one_fwd_sq;
    const can_move_fwd: bool = board.unoccupied() & one_fwd_pos != 0;

    // We can make this move so long as the square is also unoccupied.
    if (can_move_fwd) {
        moves |= one_fwd_pos;
    }

    // Next simplest case, pawn is on its starting square and can thus move two squares
    // so long as the target is unoccupied.
    const is_on_start: bool = if (color == .white)
        pos_bit & Board.RANK_2 != 0
    else pos_bit & Board.RANK_7 != 0;

    if (is_on_start and can_move_fwd) {
        // We need to do this math in this block, because without the guarantee that
        // we are on our starting space we could over / under flow the integer width.
        const two_fwd_sq = if (color == .white) position + 16 else position - 16;
        const two_fwd_pos = @as(u64, 1) << two_fwd_sq;

        if (board.unoccupied() & two_fwd_pos != 0) {
            moves |= two_fwd_pos;
        }
    }

    const diag_right_pos = if (color == .white)
        @as(u64, 1) << position + 9
    else @as(u64, 1) << position - 7;

    const diag_left_pos = if (color == .white)
        @as(u64, 1) << position + 7
    else @as(u64, 1) << position - 9;

    // If the space is occupied by a non-king piece of opposite color
    // it is capturable and thus a legal move
    const opposite_color = if (color == .white) board.black else board.white;
    if (opposite_color & ~board.kings & diag_right_pos != 0) {
        moves |= diag_right_pos;
    }
    if (opposite_color & ~board.kings & diag_left_pos != 0) {
        moves |= diag_left_pos;
    }

    return moves;
}

pub fn knightMovementMask(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit: u64 = @as(u64, 1) << position;
    
    // Rather than return an error, let's just say this state is completely illegal and crash.
    std.debug.assert((board.occupied() & pos_bit) != 0);

    const color: PieceColor = if ((board.white & pos_bit) != 0)
        PieceColor.white
    else
        PieceColor.black;
    
    const friendly_pieces = if (color == .white) board.white else board.black;
    const enemy_kings = if (color == .white) (board.kings & board.black) else (board.kings & board.white);

    const not_a_file  = ~Board.FILE_A;
    const not_ab_file = ~(Board.FILE_A | Board.FILE_B);
    const not_h_file  = ~Board.FILE_H;
    const not_gh_file = ~(Board.FILE_G | Board.FILE_H);

    var moves: u64 = 0;

    // North movements (up 2, then left or right 1)
    const n_l = (pos_bit << 15) & not_h_file;
    if ((n_l & friendly_pieces) == 0 and (n_l & enemy_kings) == 0) {
        moves |= n_l;
    }

    const n_r = (pos_bit << 17) & not_a_file;
    if ((n_r & friendly_pieces) == 0 and (n_r & enemy_kings) == 0) {
        moves |= n_r;
    }

    // South movements (down 2, then left or right 1)
    const s_r = (pos_bit >> 15) & not_a_file;
    if ((s_r & friendly_pieces) == 0 and (s_r & enemy_kings) == 0) {
        moves |= s_r;
    }
    const s_l = (pos_bit >> 17) & not_h_file;
    if ((s_l & friendly_pieces) == 0 and (s_l & enemy_kings) == 0) {
        moves |= s_l;
    }

    // East movements (right 2, then up or down 1)
    const e_n = (pos_bit << 10) & not_ab_file;
    if ((e_n & friendly_pieces) == 0 and (e_n & enemy_kings) == 0) {
        moves |= e_n;
    }
    const e_s = (pos_bit >>  6) & not_ab_file;
    if ((e_s & friendly_pieces) == 0 and (e_s & enemy_kings) == 0) {
        moves |= e_s;
    }

    // West movements (left 2, then up or down 1)
    const w_n = (pos_bit <<  6) & not_gh_file;
    if ((w_n & friendly_pieces) == 0 and (w_n & enemy_kings) == 0) {
        moves |= w_n;
    }
    const w_s = (pos_bit >> 10) & not_gh_file;
    if ((w_s & friendly_pieces) == 0 and (w_s & enemy_kings) == 0) {
        moves |= w_s;
    }

    return moves;
}

pub fn bishopMovementMask(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit: u64 = @as(u64, 1) << position;

    var moves: u64 = 0;

    // Rather than return an error, let's just say this state is completely illegal and crash.
    std.debug.assert((board.occupied() & pos_bit) != 0);

    const color: PieceColor = if ((board.white & pos_bit) != 0)
        PieceColor.white
    else
        PieceColor.black;
    
    const friendly_pieces = if (color == .white) board.white else board.black;

    // Calculate moves in each direction until we hit a piece or the edge of the board
    
    // Top-left direction
    var current_pos = position;

    if (!(pos_bit & Board.RANK_8 != 0 or pos_bit & Board.FILE_A != 0)) {
        while (current_pos <= 62) {
            current_pos += 7;
            const current_bit = @as(u64, 1) << @intCast(current_pos);

            // Hit a friendly piece or a king
            if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
                break;
            }
            
            moves |= current_bit;

            // Hit an enemy piece
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer overflow
            if ((current_bit & Board.RANK_8) != 0 or (current_bit & Board.FILE_A) != 0) {
                break;
            }
        }
    }
    
    // Top-right direction
    current_pos = position;

    if (!(pos_bit & Board.RANK_8 != 0 or pos_bit & Board.FILE_H != 0)) {
        while (current_pos <= 63) {
            current_pos += 9;
            const current_bit = @as(u64, 1) << @intCast(current_pos);
            
            if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
                break;
            }
            
            moves |= current_bit;
            
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer overflow
            if ((current_bit & Board.RANK_8) != 0 or (current_bit & Board.FILE_H) != 0) {
                break;
            }
        }
    }

    // Bottom-right direction
    current_pos = position;

    if (!(pos_bit & Board.RANK_1 != 0 or pos_bit & Board.FILE_H != 0)) {
        while (current_pos >= 1) {
            current_pos -= 7;
            const current_bit = @as(u64, 1) << @intCast(current_pos);
            
            if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
                break;
            }
            
            moves |= current_bit;
            
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer underflow
            if ((current_bit & Board.RANK_1) != 0 or (current_bit & Board.FILE_H) != 0) {
                break;
            }
        }
    }
    
    // Bottom-left direction
    current_pos = position;

    if (!(pos_bit & Board.RANK_1 != 0 or pos_bit & Board.FILE_A != 0)) {
        while (current_pos >= 0) {
            current_pos -= 9;
            const current_bit = @as(u64, 1) << @intCast(current_pos);
            
            if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
                break;
            }
            
            moves |= current_bit;
            
            if ((board.occupied() & current_bit) != 0) {
                break;
            }

            // Prevent integer underflow
            if ((current_bit & Board.RANK_1) != 0 or (current_bit & Board.FILE_A) != 0) {
                break;
            }
        }
    }

    return moves;
}

pub fn rookMovementMask(position: Board.PositionIndex, board: *const Board) u64 {
    const pos_bit: u64 = @as(u64, 1) << position;

    var moves: u64 = 0;

    // Rather than return an error, let's just say this state is completely illegal and crash.
    std.debug.assert((board.occupied() & pos_bit) != 0);

    const color: PieceColor = if ((board.white & pos_bit) != 0)
        PieceColor.white
    else
        PieceColor.black;
    
    const friendly_pieces = if (color == .white) board.white else board.black;
    const file = position % 8;

    // Calculate moves in each direction until we hit a piece or the edge of the board
    
    // Up direction
    var current_pos: u6 = position;
    while (current_pos < 56) {
        current_pos += 8;
        const current_bit = @as(u64, 1) << current_pos;

        // Hit a friendly piece or a king
        if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
            break;
        }
        
        moves |= current_bit;

        // Hit an enemy piece
        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }
    
    // Down direction
    current_pos = position;
    while (current_pos >= 8) {
        current_pos -= 8;
        const current_bit = @as(u64, 1) << current_pos;

        if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
            break;
        }
        
        moves |= current_bit;
        
        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }
    
    // Right direction
    current_pos = position;
    while (file < 7 and current_pos % 8 < 7) {
        current_pos += 1;
        const current_bit = @as(u64, 1) << current_pos;
        
        if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
            break;
        }
        
        moves |= current_bit;
        
        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }
    
    // Left direction
    current_pos = position;
    while (file > 0 and current_pos % 8 > 0) {
        current_pos -= 1;
        const current_bit = @as(u64, 1) << current_pos;
        
        if (((friendly_pieces & current_bit) != 0) or (board.occupied() & current_bit & board.kings) != 0) {
            break;
        }
        
        moves |= current_bit;
        
        if ((board.occupied() & current_bit) != 0) {
            break;
        }
    }

    return moves;
}

pub fn queenMovementMask(position: u6, board: *const Board) u64 {
    const diagonals     = bishopMovementMask(position, board);
    const rank_and_file = rookMovementMask(position, board);

    return diagonals | rank_and_file;
}

pub fn kingMovementMask(position: u6, board: *const Board) u64 {
    const king_bitboard: u64 = @as(u64, 1) << position;

    // There better be a king here.
    std.debug.assert(board.occupied() & king_bitboard != 0);

    const is_white = (board.white & king_bitboard) != 0;

    const friendly_pieces = if (is_white) board.white else board.black;

    // Prevent wrapping around the board
    const not_a_file = ~Board.FILE_A;
    const not_h_file = ~Board.FILE_H;

    var moves: u64 = 0;

    // North, North-East, East
    moves |= (king_bitboard << 8);
    moves |= (king_bitboard << 9) & not_a_file;
    moves |= (king_bitboard << 1) & not_a_file;

    // South-East, South, South-West
    moves |= (king_bitboard >> 7) & not_a_file;
    moves |= (king_bitboard >> 8);
    moves |= (king_bitboard >> 9) & not_h_file;

    // West, North-West
    moves |= (king_bitboard >> 1) & not_h_file;
    moves |= (king_bitboard << 7) & not_h_file;

    // Can't capture friends
    moves &= ~friendly_pieces;
    // Can't capture kings
    moves &= ~board.kings;

    return moves;
}

test "initializing an empty board results in all bits set to zero" {
    const b = Board.empty();
    try std.testing.expectEqual(@as(u64, 0), b.white);
    try std.testing.expectEqual(@as(u64, 0), b.black);
    try std.testing.expectEqual(@as(u64, 0), b.pawns);
    try std.testing.expectEqual(@as(u64, 0), b.knights);
    try std.testing.expectEqual(@as(u64, 0), b.bishops);
    try std.testing.expectEqual(@as(u64, 0), b.rooks);
    try std.testing.expectEqual(@as(u64, 0), b.queens);
    try std.testing.expectEqual(@as(u64, 0), b.kings);
}

test "`occupied` produces the union of bitboards `black` and `white`" {
    var board: Board = Board.empty();
    board.white = 0x0F0F0F0F0F0F0F0F;
    board.black = 0xF0F0F0F0F0F0F0F0;
    const actual = board.occupied();

    try std.testing.expectEqual(0xFFFFFFFFFFFFFFFF, actual);
}

test "`unoccupied` produces the negation of the union of bitboards `black` and `white`" {
    var board: Board = Board.empty();
    board.white = 0x0F0F0F0F0F0F0F0F;
    board.black = 0xF0F0F0F0F0F0F0F0;
    const actual = board.unoccupied();

    try std.testing.expectEqual(0x0000000000000000, actual);
}

test "Pawns can move forward if they are on the board" {
    // Create two pawns which are not on their starting spaces
    // and which have no other pieces around them.
    // Both should produce exactly one legal move, advancing a single space forward.

    var board: Board = Board.empty();

    const black_pos: Board.PositionIndex = 61;
    board.black |= @as(u64, 1) << black_pos;
    board.pawns |= @as(u64, 1) << black_pos;
    const black_moves = pawnMovementMask(black_pos, &board);
    try std.testing.expectEqual(9007199254740992, black_moves);

    const white_pos: Board.PositionIndex = 7;
    board.white |= @as(u64, 1) << white_pos;
    board.pawns |= @as(u64, 1) << white_pos;
    const white_moves: u64 = pawnMovementMask(white_pos, &board);
    try std.testing.expectEqual(32768, white_moves);
}

test "Pawns can move two spaces forward if they are in their starting rank" {
    // Create two pawns on their starting ranks.
    // Since pawns can never move backwards, this heuristic is simple and just works.
    // We expect each move list to produce two moves for each - one rank forward
    // and two ranks forward.

    var board: Board = Board.empty();

    const black_pos: Board.PositionIndex = 54;
    board.black |= @as(u64, 1) << black_pos;
    board.pawns |= @as(u64, 1) << black_pos;
    const black_moves = pawnMovementMask(black_pos, &board);
    try std.testing.expectEqual(70643622084608, black_moves);

    const white_pos: Board.PositionIndex = 11;
    board.white |= @as(u64, 1) << white_pos;
    board.pawns |= @as(u64, 1) << white_pos;
    const white_moves: u64 = pawnMovementMask(white_pos, &board);
    try std.testing.expectEqual(134742016, white_moves);
}

test "Pawns can capture if enemy pieces occupy forward-diagonal spaces" {
    var blk_board: Board = Board.empty();

    // Put a black pawn at G7
    const black_pos: Board.PositionIndex = 54;
    blk_board.black |= @as(u64, 1) << black_pos;
    blk_board.pawns |= @as(u64, 1) << black_pos;

    // Put a white queen at H8 and a white knight at H6
    const white_qn_pos: Board.PositionIndex = 47;
    blk_board.white  |= @as(u64, 1) << white_qn_pos;
    blk_board.queens |= @as(u64, 1) << white_qn_pos;

    const white_kn_pos: Board.PositionIndex = 45;
    blk_board.white   |= @as(u64, 1) << white_kn_pos;
    blk_board.knights |= @as(u64, 1) << white_kn_pos;

    // We expect the list of moves to include
    // - both diagonals (captures)
    // - advancing one rank
    // - advancing two ranks (because we're on our starting rank)
    const black_moves = pawnMovementMask(black_pos, &blk_board);
    try std.testing.expectEqual(246565482528768, black_moves);
}

test "Pawns cannot capture friendly pieces and cannot move into occupied squares" {
    // Put friendly pieces in capturable locations to verify
    // that we cannot erroneously capture pieces of our own team

    var board: Board = Board.empty();

    const pawn_pos: Board.PositionIndex = 13;
    board.white |= @as(u64, 1) << pawn_pos;
    board.pawns |= @as(u64, 1) << pawn_pos;

    const white_kn_pos: Board.PositionIndex = 22;
    board.white   |= @as(u64, 1) << white_kn_pos;
    board.knights |= @as(u64, 1) << white_kn_pos;
    const white_b_pos: Board.PositionIndex = 20;
    board.white   |= @as(u64, 1) << white_b_pos;
    board.bishops |= @as(u64, 1) << white_b_pos;

    // Put an enemy piece directly in front of us to verify that
    // we cannot advance ahead at all (despite being in starting rank)
    const blk_r_pos: Board.PositionIndex = 21;
    board.black |= @as(u64, 1) << blk_r_pos;
    board.rooks |= @as(u64, 1) << blk_r_pos;

    const moves = pawnMovementMask(pawn_pos, &board);
    // No legal moves in this board state
    try std.testing.expectEqual(0, moves);
}

test "Pawns cannot capture kings" {
    var board: Board = Board.empty();

    const pawn_pos: Board.PositionIndex = 32;
    board.black |= @as(u64, 1) << pawn_pos;
    board.pawns |= @as(u64, 1) << pawn_pos;

    const white_k1_pos: Board.PositionIndex = 25;
    board.white |= @as(u64, 1) << white_k1_pos;
    board.kings |= @as(u64, 1) << white_k1_pos;
    const white_k2_pos: Board.PositionIndex = 23;
    board.white |= @as(u64, 1) << white_k2_pos;
    board.kings |= @as(u64, 1) << white_k2_pos;

    const moves = pawnMovementMask(pawn_pos, &board);

    // We expect the pawn to only be able to move forward one space,
    // since the diagonals are occupied by kings which cannot be captured.
    try std.testing.expectEqual(16777216, moves);
}

test "Pawns cannot move beyond the boundary of the board" {
    var board: Board = Board.empty();

    const white_pos: Board.PositionIndex = 62;
    board.pawns |= @as(u64, 1) << white_pos;
    board.white |= @as(u64, 1) << white_pos;
    const white_moves = pawnMovementMask(white_pos, &board);
    try std.testing.expectEqual(0, white_moves);

    const black_pos: Board.PositionIndex = 1;
    board.pawns |= @as(u64, 1) << black_pos;
    board.black |= @as(u64, 1) << black_pos;
    const black_moves = pawnMovementMask(black_pos, &board);
    try std.testing.expectEqual(0, black_moves);
}

test "Knights can be moved in a 2 over 1 pattern of rank & file, over other pieces" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 36;

    board.knights |= @as(u64, 1) << pos;
    board.white   |= @as(u64, 1) << pos;

    // Put some pieces around the knight - These should
    // not affect movement since knights can "jump over" pieces
    board.black   |= @as(u64, 1) << 27;
    board.pawns   |= @as(u64, 1) << 27;
    board.black   |= @as(u64, 1) << 28;
    board.rooks   |= @as(u64, 1) << 28;
    board.black   |= @as(u64, 1) << 29;
    board.bishops |= @as(u64, 1) << 29;
    board.black   |= @as(u64, 1) << 35;
    board.queens  |= @as(u64, 1) << 35;
    board.black   |= @as(u64, 1) << 37;
    board.queens  |= @as(u64, 1) << 37;
    board.black   |= @as(u64, 1) << 43;
    board.kings   |= @as(u64, 1) << 43;
    board.white   |= @as(u64, 1) << 44;
    board.rooks   |= @as(u64, 1) << 44;
    board.white   |= @as(u64, 1) << 45;
    board.rooks   |= @as(u64, 1) << 45;

    const moves = knightMovementMask(pos, &board);

    try std.testing.expectEqual(11333767002587136, moves);
}


test "Knights which have all destinations unreachable cannot move" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 39;

    board.knights |= @as(u64, 1) << pos;
    board.black   |= @as(u64, 1) << pos;

    board.black  |= @as(u64, 1) << 54;
    board.rooks  |= @as(u64, 1) << 54;

    board.white  |= @as(u64, 1) << 45;
    board.kings  |= @as(u64, 1) << 45;

    board.white  |= @as(u64, 1) << 29;
    board.kings  |= @as(u64, 1) << 29;

    board.black  |= @as(u64, 1) << 22;
    board.queens |= @as(u64, 1) << 22;

    const moves = knightMovementMask(pos, &board);

    try std.testing.expectEqual(0, moves);
}


test "Rooks can move across rank and file" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 36;
    board.rooks |= @as(u64, 1) << pos;
    board.white |= @as(u64, 1) << pos;
    const moves = rookMovementMask(pos, &board);

    try std.testing.expectEqual(1157443723186933776, moves);
}

test "Rooks which are boxed in have no valid moves" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 7;
    board.rooks |= @as(u64, 1) << pos;
    board.black |= @as(u64, 1) << pos;

    board.queens |= @as(u64, 1) << 6;
    board.black  |= @as(u64, 1) << 6;

    // Can't capture kings
    board.kings |= @as(u64, 1) << 15;
    board.white |= @as(u64, 1) << 15;

    const moves = rookMovementMask(pos, &board);
    try std.testing.expectEqual(0, moves);
}

test "Bishops can move diagonally across the board" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 3;
    board.bishops |= @as(u64, 1) << pos;
    board.black   |= @as(u64, 1) << pos;

    const moves = bishopMovementMask(pos, &board);
    try std.testing.expectEqual(550848566272, moves);
}

test "Bishops with pieces at each corner can't move" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 20;
    board.bishops |= @as(u64, 1) << pos;
    board.white   |= @as(u64, 1) << pos;

    board.kings |= @as(u64, 1) << 27;
    board.black |= @as(u64, 1) << 27;

    board.kings |= @as(u64, 1) << 29;
    board.black |= @as(u64, 1) << 29;

    board.knights |= @as(u64, 1) << 13;
    board.white   |= @as(u64, 1) << 13;

    board.queens |= @as(u64, 1) << 11;
    board.white  |= @as(u64, 1) << 11;

    const moves = bishopMovementMask(pos, &board);
    try std.testing.expectEqual(0, moves);
}

test "Bishops can move along their path until they encounter a capture" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 20;
    board.bishops |= @as(u64, 1) << pos;
    board.white   |= @as(u64, 1) << pos;

    board.rooks |= @as(u64, 1) << 41;
    board.black |= @as(u64, 1) << 41;

    board.kings |= @as(u64, 1) << 29;
    board.black |= @as(u64, 1) << 29;

    board.knights |= @as(u64, 1) << 13;
    board.white   |= @as(u64, 1) << 13;

    board.queens |= @as(u64, 1) << 11;
    board.white  |= @as(u64, 1) << 11;

    const moves = bishopMovementMask(pos, &board);
    try std.testing.expectEqual(2216337342464, moves);
}

test "Queen can move across rank and file as well as diagonally" {
    var board: Board = Board.empty();

    const pos: Board.PositionIndex = 28;
    board.queens |= @as(u64, 1) << pos;
    board.black  |= @as(u64, 1) << pos;

    const moves = queenMovementMask(pos, &board);
    try std.testing.expectEqual(1266167048752878738, moves);
}

test "Queen boxed in on all sides cannot move" {
    var board: Board = Board.empty();
    const pos: Board.PositionIndex = 28;

    board.queens |= @as(u64, 1) << pos;
    board.black  |= @as(u64, 1) << pos;

    board.queens |= @as(u64, 1) << 29;
    board.black  |= @as(u64, 1) << 29;

    board.queens |= @as(u64, 1) << 37;
    board.black  |= @as(u64, 1) << 37;

    board.queens |= @as(u64, 1) << 36;
    board.black  |= @as(u64, 1) << 36;

    board.kings  |= @as(u64, 1) << 35;
    board.white  |= @as(u64, 1) << 35;

    board.kings  |= @as(u64, 1) << 27;
    board.white  |= @as(u64, 1) << 27;

    board.rooks  |= @as(u64, 1) << 19;
    board.black  |= @as(u64, 1) << 19;

    board.rooks  |= @as(u64, 1) << 20;
    board.black  |= @as(u64, 1) << 20;

    board.knights |= @as(u64, 1) << 21;
    board.black   |= @as(u64, 1) << 21;

    const moves = queenMovementMask(pos, &board);
    try std.testing.expectEqual(0, moves);
}

test "Kings can move one space at a time on an empty board with no castling privileges" {
    var board = Board.empty();
    const pos: Board.PositionIndex = 19;

    board.black |= @as(u64, 1) << pos;
    board.kings |= @as(u64, 1) << pos;

    const moves = kingMovementMask(pos, &board);
    try std.testing.expectEqual(471079936, moves);
}

test "Kings can which are boxed in by friendly pieces cannot move" {
    var board = Board.empty();
    const pos: Board.PositionIndex = 47;

    board.white |= @as(u64, 1) << pos;
    board.kings |= @as(u64, 1) << pos;

    board.white |= @as(u64, 1) << 39;
    board.rooks |= @as(u64, 1) << 39;
    board.white |= @as(u64, 1) << 38;
    board.rooks |= @as(u64, 1) << 38;
    board.white |= @as(u64, 1) << 46;
    board.rooks |= @as(u64, 1) << 46;
    board.white |= @as(u64, 1) << 54;
    board.pawns |= @as(u64, 1) << 54;
    board.white |= @as(u64, 1) << 55;
    board.kings |= @as(u64, 1) << 55;

    const moves = kingMovementMask(pos, &board);
    try std.testing.expectEqual(0, moves);
}

test "Placing piece on an empty space updates the bit-board representations" {
    var board = Board.empty();
    const pos = .C6;

    try std.testing.expectEqual(0, board.black);
    try std.testing.expectEqual(0, board.queens);

    board.setPieceAt(Piece.queen, PieceColor.black, pos);

    try std.testing.expectEqual(4398046511104, board.black);
    try std.testing.expectEqual(4398046511104, board.queens);
}

test "Using `intoBitboard` on a slice of `Position` enums is equivalent to declaring u64's manually" {
    // `init` uses comptime resolution of enum variants slices -> u64's
    const board = Board.init();

    // Each field should be equivalent to declaring the u64's manually for these positions
    try std.testing.expectEqual(               65535, board.white);
    try std.testing.expectEqual(18446462598732840960, board.black);
    try std.testing.expectEqual(   71776119061282560, board.pawns);
    try std.testing.expectEqual( 2594073385365405732, board.bishops);
    try std.testing.expectEqual( 4755801206503243842, board.knights);
    try std.testing.expectEqual( 9295429630892703873, board.rooks);
    try std.testing.expectEqual(  576460752303423496, board.queens);
    try std.testing.expectEqual( 1152921504606846992, board.kings);
}

test "Get attacked squares for pawns produces accurate bitboard" {
    var board = Board.empty();

    const pawns = comptime Position.intoBitboard(
        &[_]Position{ .A2, .B2, .C3, .D4, .E4, .F3, .G2, .H2 });

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .B3, .A3, .C3, .B4, .D4, .C5, .E5, .D5, .F5, .E4, .G4, .F3, .H3, .G3 });

    board.pawns |= pawns;
    board.white |= pawns;

    const result = attackedByPawns(board.pawns & board.white, .white);

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for rooks produces accurate bitboard" {
    var board = Board.empty();

    board.rooks |= comptime Position.intoBitboard(&[_]Position{ .E8 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .E8 });

    // Set up some pieces both friendly and foe
    board.knights |= comptime Position.intoBitboard(&[_]Position{ .G8 });
    board.white   |= comptime Position.intoBitboard(&[_]Position{ .G8 });

    board.kings   |= comptime Position.intoBitboard(&[_]Position{ .E4 });
    board.black   |= comptime Position.intoBitboard(&[_]Position{ .E4 });

    const result = attackedByRook(comptime Position.intoIndex(.E8), &board);

    // We expect the attacked squares to extend out from the rook's position,
    // inclusive to the terminal square. Terminal square includes the position
    // of the piece that we "hit", even if that piece is friendly.
    const expected = comptime Position.intoBitboard(
        &[_]Position{ .A8, .B8, .C8, .D8, .F8, .G8, // Horizontal axis
                      .E7, .E6, .E5, .E4 });        // Vertical axis

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for multiple rooks produces accurate bitboard" {
    var board = Board.empty();

    board.rooks |= comptime Position.intoBitboard(&[_]Position{ .A7, .C3, .E3, .G5, });
    board.white |= comptime Position.intoBitboard(&[_]Position{ .A7, .C3, .E3, .G5, });

    board.black  |= comptime Position.intoBitboard(&[_]Position{ .A5, .A8, .B7, .C2, .E6, .G3, .H6 });
    board.queens |= comptime Position.intoBitboard(&[_]Position{ .A5, .A8, .B7, .C2, .E6, .G3, .H6 });

    const result = attackedByRooks(board.white & board.rooks, &board);

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .A5, .A6, .A8, .B7, .A3, .B3, .B5, .C2, .C3, .C4, .C5, .C6, .C7, .C8, .D3, .D5,
                      .E1, .E2, .E3, .E4, .E5, .E6, .F3, .F5, .G3, .G4, .G6, .G7, .G8, .H5 });

    try std.testing.expectEqual(expected, result);

    // To be extra sure, check each rook attack pattern individually and make sure that
    // the result is the union of all individual sets
    const first  = attackedByRook(comptime Position.intoIndex(.A7), &board);
    const second = attackedByRook(comptime Position.intoIndex(.C3), &board);
    const third  = attackedByRook(comptime Position.intoIndex(.E3), &board);
    const fourth = attackedByRook(comptime Position.intoIndex(.G5), &board);

    const aggregate = first | second | third | fourth;
    try std.testing.expectEqual(result, aggregate);
}

test "Get attacked squares for bishops produces accurate bitboard" {
    var board = Board.empty();

    board.bishops |= comptime Position.intoBitboard(&[_]Position{ .E5 });
    board.white   |= comptime Position.intoBitboard(&[_]Position{ .E5 });

    // Set up some pieces both friendly and foe
    board.knights |= comptime Position.intoBitboard(&[_]Position{ .C3 });
    board.black   |= comptime Position.intoBitboard(&[_]Position{ .C3 });

    board.kings |= comptime Position.intoBitboard(&[_]Position{ .B8 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .B8 });

    board.queens |= comptime Position.intoBitboard(&[_]Position{ .F4 });
    board.white  |= comptime Position.intoBitboard(&[_]Position{ .F4 });

    const result = attackedByBishop(comptime Position.intoIndex(.E5), &board);

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .B8, .C3, .C7, .D4, .D6,
                      .F4, .F6, .G7, .H8 });

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for multiple bishops produces accurate bitboard" {
    var board = Board.empty();

    board.bishops |= comptime Position.intoBitboard(&[_]Position{ .A3, .C5, .E7, .G5 });
    board.white   |= comptime Position.intoBitboard(&[_]Position{ .A3, .C5, .E7, .G5 });

    board.queens |= comptime Position.intoBitboard(&[_]Position{ .B6 });
    board.black  |= comptime Position.intoBitboard(&[_]Position{ .B6 });
    board.rooks  |= comptime Position.intoBitboard(&[_]Position{ .E3 });
    board.black  |= comptime Position.intoBitboard(&[_]Position{ .E3 });

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .B2, .B4, .C1, .C5,
                      .B6, .B4, .D4, .D6, .A3, .E3, .E7,
                      .D6, .D8, .C5, .F8, .F6, .G5,
                      .E7, .E3, .F6, .F4, .H6, .H4, });

    const result = attackedByBishops(board.bishops & board.white, &board);

    try std.testing.expectEqual(expected, result);

    // To be extra sure, check each bishop attack pattern individually and make sure that
    // the result is the union of all individual sets
    const first  = attackedByBishop(comptime Position.intoIndex(.A3), &board);
    const second = attackedByBishop(comptime Position.intoIndex(.C5), &board);
    const third  = attackedByBishop(comptime Position.intoIndex(.E7), &board);
    const fourth = attackedByBishop(comptime Position.intoIndex(.G5), &board);

    const aggregate = first | second | third | fourth;
    try std.testing.expectEqual(result, aggregate);
}

test "Get attacked squares for queen produces accurate bitboard" {
    var board = Board.empty();

    board.queens |= comptime Position.intoBitboard(&[_]Position{ .D3 });
    board.white  |= comptime Position.intoBitboard(&[_]Position{ .D3 });

    // Set up some pieces both friendly and foe
    board.kings |= comptime Position.intoBitboard(&[_]Position{ .F3 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .F3 });

    board.bishops |= comptime Position.intoBitboard(&[_]Position{ .G6 });
    board.white   |= comptime Position.intoBitboard(&[_]Position{ .G6 });

    const result = attackedByQueen(comptime Position.intoIndex(.D3), &board);

    // We expect the attacked squares to extend out from the queen's position,
    // inclusive to the terminal square. Terminal square includes the position
    // of the piece that we "hit", even if that piece is friendly.
    const expected = comptime Position.intoBitboard(
        &[_]Position{ .A3, .B3, .C3, .E3, .F3,
                      .B1, .C2, .A6, .B5, .C4,
                      .D1, .D2, .D4, .D5, .D6, .D7, .D8,
                      .E4, .F5, .G6, .E2, .F1 });

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for multiple queens produces accurate bitboard" {
    var board = Board.empty();

    board.queens |= comptime Position.intoBitboard(&[_]Position{ .A3, .G3, .C5, .C7 });
    board.black  |= comptime Position.intoBitboard(&[_]Position{ .A3, .G3, .C5, .C7 });

    board.kings |= comptime Position.intoBitboard(&[_]Position{ .C3, .E3 });
    board.white |= comptime Position.intoBitboard(&[_]Position{ .C3, .E3 });

    board.rooks |= comptime Position.intoBitboard(&[_]Position{ .E7, .G7 });
    board.white |= comptime Position.intoBitboard(&[_]Position{ .E7, .G7 });

    const result = attackedByQueens(board.queens & board.black, &board);

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .A1, .A2, .A3, .A4, .A5, .A6, .A7, .A8,
                      .B2, .B3, .B4, .B5, .B6, .B7, .B8,
                      .C1, .C3, .C4, .C5, .C6, .C7, .C8,
                      .D4, .D5, .D6, .D7, .D8,
                      .E1, .E3, .E5, .E7,
                      .F2, .F3, .F4, .F5,
                      .G1, .G2, .G3, .G4, .G5, .G6, .G7,
                      .H2, .H3, .H4, .H5 });

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for king produces accurate bitboard" {
    var board = Board.empty();

    board.kings |= comptime Position.intoBitboard(&[_]Position{ .C8 });
    board.white |= comptime Position.intoBitboard(&[_]Position{ .C8 });

    board.pawns |= comptime Position.intoBitboard(&[_]Position{ .C7, .D8 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .C7, .D8 });

    const result = attackedByKing(comptime Position.intoIndex(.C8), &board);

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .B8, .B7, .C7, .D7, .D8 });

    try std.testing.expectEqual(expected, result);
}


test "Get attacked squares for multiple kings produces accurate bitboard" {
    var board = Board.empty();

    board.kings |= comptime Position.intoBitboard(&[_]Position{ .A5, .H3, .D2 });
    board.white |= comptime Position.intoBitboard(&[_]Position{ .A5, .H3, .D2 });

    board.pawns |= comptime Position.intoBitboard(&[_]Position{ .B5, .E3, .G3, .H2 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .B5, .E3, .G3, .H2 });

    const result = attackedByKings(board.kings & board.white, &board);

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .A4, .A6, .B4, .B5, .B6, .C1, .C2, .C3, .D1, .D3,
                      .E1, .E2, .E3, .G2, .G3, .G4, .H2, .H4 });

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for knight produces accurate bitboard" {
    var board = Board.empty();

    board.knights |= comptime Position.intoBitboard(&[_]Position{ .C2 });
    board.white   |= comptime Position.intoBitboard(&[_]Position{ .C2 });

    board.rooks |= comptime Position.intoBitboard(&[_]Position{ .A1, .D4, .E3 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .A1, .D4, .E3 });

    const result = attackedByKnight(comptime Position.intoIndex(.C2), &board);

    const expected = comptime Position.intoBitboard(&[_]Position{ .A1, .A3, .B4, .D4, .E3, .E1 });

    try std.testing.expectEqual(expected, result);
}


test "Get attacked squares for multiple knights produces accurate bitboard" {
    var board = Board.empty();

    board.knights |= comptime Position.intoBitboard(&[_]Position{ .C2, .E6, .B7 });
    board.white   |= comptime Position.intoBitboard(&[_]Position{ .C2, .E6, .B7 });

    board.rooks |= comptime Position.intoBitboard(&[_]Position{ .A1, .D4, .E3, .F8 });
    board.black |= comptime Position.intoBitboard(&[_]Position{ .A1, .D4, .E3, .F8 });

    const result = attackedByKnights(board.knights & board.white, &board);

    const expected = comptime Position.intoBitboard(
        &[_]Position{ .A1, .A3, .A5, .B4, .C5, .C7, .D4,
                      .D6, .D8, .E3, .E1, .F4, .F8, .G5, .G7 });

    try std.testing.expectEqual(expected, result);
}

test "Get attacked squares for entire team produces accurate bitboard" {
    {
        const board = Board.init();

        const result = attackMask(.white, &board);
        const expected = Board.RANK_1 & ~(Board.FILE_A & Board.RANK_1)
                                     & ~(Board.FILE_H & Board.RANK_1)
                                     | Board.RANK_2
                                     | Board.RANK_3;

        try std.testing.expectEqual(expected, result);
    }

    {
        var board = Board.empty();
        // White pieces
        board.setPieceAt(.king,   .white, .E1);
        board.setPieceAt(.queen,  .white, .D4);
        board.setPieceAt(.rook,   .white, .A1);
        board.setPieceAt(.rook,   .white, .F1);
        board.setPieceAt(.bishop, .white, .C4);
        board.setPieceAt(.bishop, .white, .G2);
        board.setPieceAt(.knight, .white, .F3);
        board.setPieceAt(.pawn,   .white, .A2);
        board.setPieceAt(.pawn,   .white, .B2);
        board.setPieceAt(.pawn,   .white, .E4);
        board.setPieceAt(.pawn,   .white, .F2);
        board.setPieceAt(.pawn,   .white, .G3);
        board.setPieceAt(.pawn,   .white, .H2);
        
        // Black pieces for context
        board.setPieceAt(.king,   .black, .E8);
        board.setPieceAt(.queen,  .black, .D8);
        board.setPieceAt(.rook,   .black, .A8);
        board.setPieceAt(.rook,   .black, .F8);
        board.setPieceAt(.bishop, .black, .B7);
        board.setPieceAt(.pawn,   .black, .A7);
        board.setPieceAt(.knight, .black, .C6);
        board.setPieceAt(.pawn,   .black, .B6);
        board.setPieceAt(.pawn,   .black, .E5);
        board.setPieceAt(.pawn,   .black, .F7);
        board.setPieceAt(.pawn,   .black, .G7);
        board.setPieceAt(.pawn,   .black, .H7);

        const result = attackMask(.white, &board);
        
        // White's attacked squares in this position
        const expected = comptime Position.intoBitboard(&[_]Position{
            // King attacks
            .D1, .D2, .E2, .F2, .F1,
            // Queen attacks (diagonal and straight lines from D4)
            .D1, .D2, .D3, .D5, .D6, .D7, .D8,
            .C4, .E4,
            .B2, .C3, .E5,
            .F2, .E3, .C5, .B6,
            // Rook attacks
            .A2, .F2,
            .B1, .C1, .D1, .E1, .G1, .H1,
            // Bishop attacks
            .A2, .B3, .D5, .E6, .F7,
            .B5, .A6,
            .D3, .E2, .F1,
            .F7, .E4, .D5,
            .F3, .H3, .H1,
            // Knight attacks
            .D2, .D4, .E1, .E5, .G1, .G5, .H2, .H4,
            // Pawn attacks
            .A3, .B3, .C3, .D5, .F5, .E3, .G3, .F4, .H4,
        });
        
        try std.testing.expectEqual(expected, result);
    }
}

test "Board can retrieve pieces by position" {
    const board = Board.init();

    {
        const result = board.getPieceAt(.A4);
        const expected = Board.GetPieceError.PositionUnoccupied;

        try std.testing.expectEqual(expected, result);
    }

    {
        const result = board.getPieceAt(.D1);
        const expected = PieceInfo{ .piece = .queen, .color = .white };

        try std.testing.expectEqual(expected, result);
    }

    {
        const result = board.getPieceAt(.G7);
        const expected = PieceInfo{ .piece = .pawn, .color = .black };

        try std.testing.expectEqual(expected, result);
    }
}

test "Removing piece at unoccupied square returns an error" {
    var board = Board.init();

    const result = board.removePieceAt(.A4);
    try std.testing.expectEqual(Board.RemovePieceError.PositionUnoccupied, result);
}

test "Removing piece produces updated bitboards" {
    var board = Board.init();

    try board.removePieceAt(.D7);
    try std.testing.expectEqual(
        board.pawns & board.black,
        comptime Position.intoBitboard(&[_]Position{ .A7, .B7, .C7, .E7, .F7, .G7, .H7 }));

    try std.testing.expectEqual(
        comptime Position.intoBitboard(
            &[_]Position{ .B8, .C8, .D8, .E8, .F8, .G8, // back row (except rooks) still all attacked
                          .A7, .B7, .C7, .D7, .E7, .F7, .G7, .H7, // pawn row is still all attacked
                          .A6, .B6, .C6, .D6, .E6, .F6, .G6, .H6, // remaining pawns attacked sq's
                          .D7, .D6, .D5, .D4, .D3, .D2, // uncovered queen's attacked sq's
                          .D7, .E6, .F5, .G4, .H3, // uncovered bishop's attacked sq's
            }),
        board.attacked_by_black);
}

test "Applying movement from an unoccupied square returns an error" {
    var board = Board.init();

    // Nobody is on A5
    const result = board.applyMove(.A5, .A6);
    try std.testing.expectEqual(Board.ApplyMoveError.OriginUnoccupied, result);
}

test "Applying illegal movement returns an error" {
    var board = Board.init();

    const result = board.applyMove(.H1, .H5);
    try std.testing.expectEqual(Board.ApplyMoveError.IllegalMove, result);
}

test "Applying legal move which moves into check produces an error" {
    var board = Board.empty();

    // The white knight is blocking the rook's attack, which would put the king in check
    board.setPieceAt(.king, .white, .A4);
    board.setPieceAt(.knight, .white, .A5);
    board.setPieceAt(.rook, .black, .A8);

    // Try to move the knight out of the rook's path, producing check
    const result = board.applyMove(.A5, .B7);

    try std.testing.expectEqual(Board.ApplyMoveError.MoveIntoCheck, result);
}

test "Applying legal move updates the board" {
    var board = Board.empty();

    board.setPieceAt(.knight, .black, .C6);
    board.setPieceAt(.rook, .white, .B4);
    board.setPieceAt(.bishop, .white, .D1);

    try board.applyMove(.C6, .B4);

    const expected_bishops = Position.intoBitboard(&[_]Position{ .D1 });
    const expected_rooks   = 0;
    const expected_knights = Position.intoBitboard(&[_]Position{ .B4 });
    const expected_w_atk   = Position.intoBitboard(&[_]Position{ .C2, .B3, .A4, .E2, .F3, .G4, .H5 });
    const expected_b_atk   = Position.intoBitboard(&[_]Position{ .A2, .A6, .C2, .C6, .D3, .D5  });

    try std.testing.expectEqual(expected_bishops, board.bishops);
    try std.testing.expectEqual(expected_rooks,   board.rooks);
    try std.testing.expectEqual(expected_knights, board.knights);
    try std.testing.expectEqual(expected_w_atk,   board.attacked_by_white);
    try std.testing.expectEqual(expected_b_atk,   board.attacked_by_black);
}

