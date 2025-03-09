const std = @import("std");
const mem = std.mem;


// This section is based on the specification of the UCI protocol
// described at https://gist.github.com/DOBRO/2592c6dad754ba67e6dcaec8c90165bf

pub const UciCommand = enum {
    pub const GuiToEngineCommand = union(enum) {
        uci,
        debug: bool, // allowed tokens "on" and "off"
        isready,
        setoption, // allowed token [name <id> {value <x>}]
        register, // allowed tokens "later", "name <x>", "code <y>"
        ucinewgame,
        position, // [fen <fenstring> | startpos ]  moves <move1> .... <movei>
        go, // tons of subcommands
        stop,
        ponderhit,
        quit,

        const This = @This();

        pub fn fromString(str: *const []const u8) GuiToEngineCommand {
            var parts = mem.splitScalar(u8, str.*, ' ');

            const first = parts.first();

            if (mem.eql(u8, first, "uci")) {
                return .uci;

            } else if (mem.eql(u8, first, "debug")) {
                while (parts.next()) |option| {
                    if (mem.eql(u8, option, "on")) {
                        return GuiToEngineCommand{ .debug = true };
                    } else if (mem.eql(u8, option, "off")) {
                        return GuiToEngineCommand{ .debug = false };
                    }
                }

            } else if (mem.eql(u8, first, "quit")) {
                std.debug.print("Could not deserialize a {s} from input '{s}'\n", .{ @typeName(This), str });
                unreachable;

            } else {
                std.debug.print("Could not deserialize a {s} from input '{s}'\n", .{ @typeName(This), str });
                unreachable;

            }

            unreachable;
        }
    };

    pub const EngineToGuiCommandId = union(enum) {
        name:   []const u8,
        author: []const u8,
    };

    pub const EngineToGuiCommand = union(enum) {
        id: EngineToGuiCommandId,
        uciok,
        readyok,
        bestmove,

        // These two are unimplemented for now
        copyprotection,
        registration,

        info, // tons of subcommands
        option, // tons of subcommands
    };
};

// Used to communicate with the engine, and for the engine to communicate
// with the UI
pub fn Interface(comptime ReaderType: type, comptime WriterType: type) type {
    return struct {
        input_stream: ReaderType,
        output_stream: WriterType,

        pub fn init(input_stream: anytype, output_stream: anytype) @This() {
            return .{
                .input_stream  = input_stream,
                .output_stream = output_stream,
            };
        }

        pub fn poll(self: *@This()) !?UciCommand.GuiToEngineCommand {
            var buf: [128]u8 = undefined;
            const input = try self.input_stream.readUntilDelimiterOrEof(&buf, '\n');

            if (input == null) {
                return null;
            }

            return UciCommand.GuiToEngineCommand.fromString(&input.?);
        }

        pub fn send(self: *@This(), command: UciCommand.EngineToGuiCommand) !void {
            switch (command) {
                .id => |subcommand| {
                    switch (subcommand) {
                        .author => {
                            try self.output_stream.print("id author Daniel\n", .{});
                        },
                        .name => {
                            try self.output_stream.print("id name Talwar [development]\n", .{});
                        },
                    }
                },
                .uciok => {
                    try self.output_stream.print("uciok\n", .{});
                },
                else => {
                    unreachable;
                }
            }
        }

        pub fn onInputCommand(self: *@This(), input: UciCommand.GuiToEngineCommand) !void {
            switch (input) {
                .uci => {
                    try self.send(.{ .id = .{ .name = "Name" }});
                    try self.send(.{ .id = .{ .author = "Author" }});
                    try self.send(.uciok);
                },
                else => {
                    unreachable;
                }
            }
        }
    };
}

test "Parse command from string" {
    try std.testing.expectEqual(
        .uci,
        UciCommand.GuiToEngineCommand.fromString(&"uci   ignorethis"));

    try std.testing.expectEqual(
        .{ .debug = true },
        UciCommand.GuiToEngineCommand.fromString(&"debug on"));

    try std.testing.expectEqual(
        .{ .debug = false },
        UciCommand.GuiToEngineCommand.fromString(&"debug off"));

    try std.testing.expectEqual(
        .{ .debug = false },
        UciCommand.GuiToEngineCommand.fromString(&"debug ignored off ignoredagain"));
}

