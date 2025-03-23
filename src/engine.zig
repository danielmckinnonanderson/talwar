const std       = @import("std");
const bitboards = @import("bitboards.zig");
const uci       = @import("uci.zig");
const Board     = bitboards.Board;

pub const EngineConfig = struct {
    debug: bool,
    opts: Opts,

    pub const Opts = struct {
        // None for now
    };

    pub fn init() EngineConfig {
        return EngineConfig {
            .debug = false,
            .opts = .{},
        };
    }
};

pub const HandlerError = error { Unimplemented };

pub fn handleCommand(
    cfg: *EngineConfig,
    cmd: uci.Uci.EngineCommand,
    output_writer: anytype,
) !void {
    const GuiCommand = uci.Uci.GuiCommand;

    switch (cmd) {
        .uci => {
            try uci.send(
                output_writer,
                GuiCommand{ .id = .{ .author = "Daniel" }});
            try uci.send(
                output_writer,
                GuiCommand{ .id = .{ .name = "talwar [development]" }});

            // TODO - Send `option` command here for all parameters that can be changed in engine
            try uci.send(output_writer, .uciok);
        },
        .debug => |is_enabled| {
            cfg.debug = is_enabled;
        },
        else => {
            return HandlerError.Unimplemented;
        }
    }
}

