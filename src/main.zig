const std       = @import("std");
const bitboards = @import("bitboards.zig");
const uci       = @import("uci.zig");

pub fn main() !void {
    const stdin  = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    const Interface = uci.Interface(@TypeOf(stdin), @TypeOf(stdout));
    var interface = Interface.init(stdin, stdout);

    // TODO - Poll on new input to stdin (wait for some amount of time between polls)
    //        On new input, parse it into command and respond accordingly
    while (true) {
        const cmd: ?uci.UciCommand.GuiToEngineCommand = try interface.poll();
        if (cmd == null) {
            continue;
        }

        try interface.onInputCommand(cmd.?);
    }
}

