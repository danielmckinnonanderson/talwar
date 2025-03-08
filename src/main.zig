const std = @import("std");
const bitboards = @import("./bitboards.zig");

pub fn main() !void {
    const b = bitboards.Board.init();
    std.debug.print("{}\n", .{b});
}

