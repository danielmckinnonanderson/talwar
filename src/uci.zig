const std = @import("std");
const mem = std.mem;


// This section is based on the specification of the UCI protocol
// described at https://gist.github.com/DOBRO/2592c6dad754ba67e6dcaec8c90165bf

pub const UciCommand = enum {
    pub const GuiToEngineCommand = enum {
        uci,
        debug, // allowed tokens "on" and "off"
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
            if (mem.eql(u8, str.*, comptime std.enums.tagName(GuiToEngineCommand, .uci).?)) {
                return .uci;
            } else if (mem.eql(u8, str.*, comptime std.enums.tagName(GuiToEngineCommand, .debug).?)) {
                std.debug.print("Hit a command that has a payload and lost it!\n", .{});
                unreachable;
            } else if (mem.eql(u8, str.*, comptime std.enums.tagName(GuiToEngineCommand, .quit).?)) {
                std.debug.print("Could not deserialize a {s} from input '{s}'\n", .{ @typeName(This), str });
                unreachable;
            } else {
                std.debug.print("Could not deserialize a {s} from input '{s}'\n", .{ @typeName(This), str });
                unreachable;
            }
        }
    };

    pub const EngineToGuiCommand = enum {
        id, // subcommands "name <x>", "author <y>"
        uciok,
        readyok,
        bestmove,

        // These two are unimplemented for now
        // copyprotection,
        // registration

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

        pub fn send(self: *@This(), command: UciCommand.EngineToGuiCommand) !void {
            _ = self;
            switch (command) {
                .id => {
                },
                else => {
                },
            }
        }

        /// On receipt of a new line to the input reader, attempt to parse the
        /// line into a command
        pub inline fn onReceivedCommand(line: *[]u8) ?UciCommand.GuiToEngineCommand {
            const parsed = UciCommand.GuiToEngineCommand.fromString(line);
            _ = parsed;

            return null;
        }
    };
}

test "Parse command from string" {
    try std.testing.expectEqual(
        UciCommand.GuiToEngineCommand.uci,
        UciCommand.GuiToEngineCommand.fromString(&"uci"));
}

