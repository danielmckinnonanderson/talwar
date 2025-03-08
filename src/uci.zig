const std = @import("std");


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
                .input_stream = input_stream,
                .output_stream = output_stream,
            };
        }

        pub fn send(self: *@This(), command: UciCommand.EngineToGuiCommand) !void {
            switch (command) {
                .id => {
                    try self.output_stream.print("go\n", .{});
                },
                else => {
                    _ = try self.output_stream.write("else!\n");
                },
            }
        }
    };
}

test "Invalid commands in input stream produce recoverable errors" {
    const input = "invalidcommand\nanotherone";
    var input_stream = std.io.fixedBufferStream(input);
    const input_reader = input_stream.reader();

    var output_buffer = [_]u8{0} ** 1024;
    var output_stream = std.io.fixedBufferStream(&output_buffer);
    const output_writer = output_stream.writer();

    const TestInterface = Interface(@TypeOf(input_reader), @TypeOf(output_writer));
    var interface = TestInterface.init(input_reader, output_writer);
    try interface.send(.uciok);

    try std.testing.expectEqualStrings("else!\n", output_buffer[0..6]);
}

