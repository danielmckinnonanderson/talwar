const std       = @import("std");
const bitboards = @import("bitboards.zig");
const uci       = @import("uci.zig");

pub fn main() !void {
    const stdin  = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    const Interface = uci.Interface(@TypeOf(stdin), @TypeOf(stdout));
    const interface = Interface.init(stdin, stdout);
    _ = interface;

    // TODO - Utilize multiple processes: One for I/O and one for the evaluation part
    // TODO - Poll on new input to stdin (wait for some amount of time between polls)
    //        On new input, parse it into command and respond accordingly
}

