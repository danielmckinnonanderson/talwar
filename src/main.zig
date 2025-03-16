const std       = @import("std");
const bitboards = @import("bitboards.zig");
const logging   = @import("logging.zig");
const uci       = @import("uci.zig");
const Engine    = @import("engine.zig").Engine;

pub fn main() !void {
    var logger = try logging.Logger.init("talwar.log", .debug);
    errdefer logger.deinit();

    var engine = Engine.init();

    const stdin  = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    const Interface = uci.Interface(@TypeOf(stdin), @TypeOf(stdout));
    var interface = Interface.init(stdin, stdout);

    try logger.debug("Talwar started up");

    // TODO - Poll on new input to stdin (wait for some amount of time between polls)
    //        On new input, parse it into command and respond accordingly
    while (true) {
        const cmd: ?uci.Uci.EngineCommand = interface.poll() catch {
            try logger.printerr("Error while reading command from input");
            continue;
        };

        if (cmd == null) {
            continue;
        }

        // TODO - Fix logging so this is actually useful...
        try logger.info("Received command...");

        try engine.handleCommand(&interface, cmd.?);
    }
}

