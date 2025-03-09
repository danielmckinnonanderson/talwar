const std       = @import("std");
const bitboards = @import("bitboards.zig");
const uci       = @import("uci.zig");

pub fn main() !void {
    const stdin  = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    const Interface = uci.Interface(@TypeOf(stdin), @TypeOf(stdout));
    const interface = Interface.init(stdin, stdout);
    _ = interface;

    const b = bitboards.Board.init();
    std.debug.print("{}\n", .{b});
}

