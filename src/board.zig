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
        return Board {
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
const MovementCalculationError = error{ NoPieceToMove, IncorrectPieceType };

/// Place a piece at an empty space.
/// If the space is occupied, raises `PlacementError.PositionOccupied`.
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
// TODO - Account for moves which require "move history", like en passant and castling.

pub fn getPawnMoves(position: Board.Position, board: *const Board) MovementCalculationError!u64 {
    const occupied = getOccupied(board);
    const pos_bit: u64 = @as(u64, 1) << position;

    var moves: u64 = 0;

    if ((occupied & pos_bit) == 0) {
        return MovementCalculationError.NoPieceToMove;
    }

    if ((occupied & pos_bit) != 0 and ((board.pawns & pos_bit) == 0)) {
        return MovementCalculationError.IncorrectPieceType;
    }

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
    const can_move_fwd: bool = ~occupied & one_fwd_pos != 0;

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

        if (~occupied & two_fwd_pos != 0) {
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

pub fn getRookMoves(position: Board.Position, board: *const Board) MovementCalculationError!u64 {
    const occupied = getOccupied(board);
    const pos_bit: u64 = @as(u64, 1) << position;

    var moves: u64 = 0;

    if ((occupied & pos_bit) == 0) {
        return MovementCalculationError.NoPieceToMove;
    }

    if ((occupied & pos_bit) != 0 and ((board.rooks & pos_bit) == 0)) {
        return MovementCalculationError.IncorrectPieceType;
    }

    moves = 0;

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
        if (((friendly_pieces & current_bit) != 0) or (occupied & current_bit & board.kings) != 0) {
            break;
        }
        
        moves |= current_bit;

        // Hit an enemy piece
        if ((occupied & current_bit) != 0) {
            break;
        }
    }
    
    // Down direction
    current_pos = position;
    while (current_pos >= 8) {
        current_pos -= 8;
        const current_bit = @as(u64, 1) << current_pos;
        
        if ((friendly_pieces & current_bit) != 0) {
            break;
        }
        
        moves |= current_bit;
        
        if ((occupied & current_bit) != 0) {
            break;
        }
    }
    
    // Right direction
    current_pos = position;
    while (file < 7 and current_pos % 8 < 7) {
        current_pos += 1;
        const current_bit = @as(u64, 1) << current_pos;
        
        if ((friendly_pieces & current_bit) != 0) {
            break;
        }
        
        moves |= current_bit;
        
        if ((occupied & current_bit) != 0) {
            break;
        }
    }
    
    // Left direction
    current_pos = position;
    while (file > 0 and current_pos % 8 > 0) {
        current_pos -= 1;
        const current_bit = @as(u64, 1) << current_pos;
        
        if ((friendly_pieces & current_bit) != 0) {
            break;
        }
        
        moves |= current_bit;
        
        if ((occupied & current_bit) != 0) {
            break;
        }
    }

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

test "Pawns can move forward if they are on the board" {
    // Create two pawns which are not on their starting spaces
    // and which have no other pieces around them.
    // Both should produce exactly one legal move, advancing a single space forward.

    var board: Board = Board.init();

    const black_pos: Board.Position = 61;
    board.black |= @as(u64, 1) << black_pos;
    board.pawns |= @as(u64, 1) << black_pos;
    const black_moves = try getPawnMoves(black_pos, &board);
    try std.testing.expectEqual(9007199254740992, black_moves);

    const white_pos: Board.Position = 7;
    board.white |= @as(u64, 1) << white_pos;
    board.pawns |= @as(u64, 1) << white_pos;
    const white_moves: u64 = try getPawnMoves(white_pos, &board);
    try std.testing.expectEqual(32768, white_moves);
}

test "Pawns can move two spaces forward if they are in their starting rank" {
    // Create two pawns on their starting ranks.
    // Since pawns can never move backwards, this heuristic is simple and just works.
    // We expect each move list to produce two moves for each - one rank forward
    // and two ranks forward.

    var board: Board = Board.init();

    const black_pos: Board.Position = 54;
    board.black |= @as(u64, 1) << black_pos;
    board.pawns |= @as(u64, 1) << black_pos;
    const black_moves = try getPawnMoves(black_pos, &board);
    try std.testing.expectEqual(70643622084608, black_moves);

    const white_pos: Board.Position = 11;
    board.white |= @as(u64, 1) << white_pos;
    board.pawns |= @as(u64, 1) << white_pos;
    const white_moves: u64 = try getPawnMoves(white_pos, &board);
    try std.testing.expectEqual(134742016, white_moves);
}

test "Pawns can capture if enemy pieces occupy forward-diagonal spaces" {
    var blk_board: Board = Board.init();

    // Put a black pawn at G7
    const black_pos: Board.Position = 54;
    blk_board.black |= @as(u64, 1) << black_pos;
    blk_board.pawns |= @as(u64, 1) << black_pos;

    // Put a white queen at H8 and a white knight at H6
    const white_qn_pos: Board.Position = 47;
    blk_board.white  |= @as(u64, 1) << white_qn_pos;
    blk_board.queens |= @as(u64, 1) << white_qn_pos;

    const white_kn_pos: Board.Position = 45;
    blk_board.white   |= @as(u64, 1) << white_kn_pos;
    blk_board.knights |= @as(u64, 1) << white_kn_pos;

    // We expect the list of moves to include
    // - both diagonals (captures)
    // - advancing one rank
    // - advancing two ranks (because we're on our starting rank)
    const black_moves = try getPawnMoves(black_pos, &blk_board);
    try std.testing.expectEqual(246565482528768, black_moves);
}

test "Pawns cannot capture friendly pieces and cannot move into occupied squares" {
    // Put friendly pieces in capturable locations to verify
    // that we cannot erroneously capture pieces of our own team

    var board: Board = Board.init();

    const pawn_pos: Board.Position = 13;
    board.white |= @as(u64, 1) << pawn_pos;
    board.pawns |= @as(u64, 1) << pawn_pos;

    const white_kn_pos: Board.Position = 22;
    board.white   |= @as(u64, 1) << white_kn_pos;
    board.knights |= @as(u64, 1) << white_kn_pos;
    const white_b_pos: Board.Position = 20;
    board.white   |= @as(u64, 1) << white_b_pos;
    board.bishops |= @as(u64, 1) << white_b_pos;

    // Put an enemy piece directly in front of us to verify that
    // we cannot advance ahead at all (despite being in starting rank)
    const blk_r_pos: Board.Position = 21;
    board.black |= @as(u64, 1) << blk_r_pos;
    board.rooks |= @as(u64, 1) << blk_r_pos;

    const moves = try getPawnMoves(pawn_pos, &board);
    // No legal moves in this board state
    try std.testing.expectEqual(0, moves);
}

test "Pawns cannot capture kings" {
    var board: Board = Board.init();

    const pawn_pos: Board.Position = 32;
    board.black |= @as(u64, 1) << pawn_pos;
    board.pawns |= @as(u64, 1) << pawn_pos;

    const white_k1_pos: Board.Position = 25;
    board.white |= @as(u64, 1) << white_k1_pos;
    board.kings |= @as(u64, 1) << white_k1_pos;
    const white_k2_pos: Board.Position = 23;
    board.white |= @as(u64, 1) << white_k2_pos;
    board.kings |= @as(u64, 1) << white_k2_pos;

    const moves = try getPawnMoves(pawn_pos, &board);

    // We expect the pawn to only be able to move forward one space,
    // since the diagonals are occupied by kings which cannot be captured.
    try std.testing.expectEqual(16777216, moves);
}

test "Pawns cannot move beyond the boundary of the board" {
    var board: Board = Board.init();

    const white_pos: Board.Position = 62;
    board.pawns |= @as(u64, 1) << white_pos;
    board.white |= @as(u64, 1) << white_pos;
    const white_moves = try getPawnMoves(white_pos, &board);
    try std.testing.expectEqual(0, white_moves);

    const black_pos: Board.Position = 1;
    board.pawns |= @as(u64, 1) << black_pos;
    board.black |= @as(u64, 1) << black_pos;
    const black_moves = try getPawnMoves(black_pos, &board);

    try std.testing.expectEqual(0, black_moves);
}

test "Rooks can move across rank and file" {
    var board: Board = Board.init();

    const pos: Board.Position = 36;
    board.rooks |= @as(u64, 1) << pos;
    board.white |= @as(u64, 1) << pos;
    const moves = try getRookMoves(pos, &board);

    try std.testing.expectEqual(1157443723186933776, moves);
}

test "Rooks which are boxed in have no valid moves" {
    var board: Board = Board.init();

    const pos: Board.Position = 7;
    board.rooks |= @as(u64, 1) << pos;
    board.black |= @as(u64, 1) << pos;

    board.queens |= @as(u64, 1) << 6;
    board.black  |= @as(u64, 1) << 6;

    // Can't capture kings
    board.kings |= @as(u64, 1) << 15;
    board.white |= @as(u64, 1) << 15;

    const moves = try getRookMoves(pos, &board);
    try std.testing.expectEqual(0, moves);
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

