const std       = @import("std");
const bitboards = @import("bitboards.zig");
const uci       = @import("uci.zig");
const Board     = bitboards.Board;

pub const Engine = struct {
    debug: bool,

    pub fn init() Engine {
        return Engine {
            .debug = false,
        };
    }

    pub const CommandHandlerError = error {};

    pub fn handleCommand(
        self: *Engine,
        interface: anytype,
        cmd: uci.Uci.EngineCommand,
    ) !void {
        _ = self;

        switch (cmd) {
            .uci => {
                try interface.send(uci.Uci.GuiCommand{ .id = .{ .author = "Daniel" }});
                try interface.send(uci.Uci.GuiCommand{ .id = .{ .name = "talwar [development]" }});

                // TODO - Send `option` command here for all parameters that can be changed in engine

                try interface.send(.uciok);
            },
            else => {
                unreachable;
            }
        }
    }
};

