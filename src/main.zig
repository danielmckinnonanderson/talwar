const std       = @import("std");
const bitboards = @import("bitboards.zig");
const engine    = @import("engine.zig");
const logging   = @import("logging.zig");
const uci       = @import("uci.zig");


pub fn main() !void {
    var logger = try logging.Logger.init("talwar.log", .debug);
    errdefer logger.deinit();

    const stdin  = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try logger.debug("Talwar started up", .{});

    // NOTE - Protocol seems to stipulate that this should only
    //        happen when the UI tells us to initialize.
    //        Leaving it for now for the sake of my mental model.
    var cfg = engine.EngineConfig.init();

    // TODO - Poll on new input to stdin (wait for some amount of time between polls)
    //        On new input, parse it into command and respond accordingly
    while (true) {
        const cmd = uci.poll(stdin) catch {
            try logger.printerr("Error while trying to read command from input", .{});
            continue;
        };

        if (cmd == null) {
            continue;
        }

        try logger.debug("Received command `{any}`", .{cmd.?});
        try engine.handleCommand(&cfg, cmd.?, stdout);
    }
}

