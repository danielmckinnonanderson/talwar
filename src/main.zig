const std = @import("std");
const board = @import("./board.zig");

pub fn main() !void {
    const b = board.Board.init();
    std.debug.print("{}\n", .{b});
}

