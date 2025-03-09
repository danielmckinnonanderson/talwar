const std = @import("std");
const mem = std.mem;


// This section is based on the specification of the UCI protocol
// described at https://gist.github.com/DOBRO/2592c6dad754ba67e6dcaec8c90165bf

pub const UciCommand = enum {
    pub const GuiToEngineCommand = union(enum) {
        uci,
        debug: bool, // allowed tokens "on" and "off"
        isready,
        setoption: struct {
            name: []const u8,
            // Not all options have a value, and those that do
            // can have values of different types (string, int, bool)
            // so for now we'll store this as a string and determine if
            // we want to use a union or something later.
            value: ?[]const u8,
        },
        register: union(enum) {
            later,
            now: struct {
                // The spec seems to indicate that these can be set in the same
                // command, but it's unclear if they can also be set individually.
                // For now I'm marking them both optional
                name: ?[]const u8,
                // Example shows an integer, but I don't know if that is always
                // the case. Leaving this as a string for now.
                code: ?[]const u8,
            },
        },
        ucinewgame, // unclear how to handle this one
        position, // [fen <fenstring> | startpos ]  moves <move1> .... <movei>
        go, // tons of subcommands
        stop,
        ponderhit,
        quit,

        const This = @This();

        /// Parse a string literal into a command from the GUI to the engine, including
        /// the command's payload.
        /// Current behavior is to **crash** on unparseable command strings, since at this
        /// stage all bugs should be assumed to originate from this codebase rather than from
        /// the UI.
        // TODO - Don't crash on bad commands once this implementation is reasonably stable.
        // TODO - All the string comparison here is surely expensive, figure out if it is
        //        actually unavoidable.
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
            } else if (mem.eql(u8, first, "isready")) {
                return .isready;

            } else if (mem.eql(u8, first, "setoption")) {
                const name_label = parts.next();
                std.debug.assert(name_label != null);
                std.debug.assert(mem.eql(u8, name_label.?, "name"));

                const option_name = parts.next();
                std.debug.assert(option_name != null);

                const value_label = parts.next();
                if (value_label == null) {
                    // If there's no value, then the command is complete
                    // and we can be finished
                    return GuiToEngineCommand{ .setoption = .{ .name = option_name.?, .value = null } };
                }

                // otherwise, continue parsing to get the value for the
                // option being set
                std.debug.assert(mem.eql(u8, value_label.?, "value"));

                const option_value = parts.next();
                std.debug.assert(option_value != null);
                return GuiToEngineCommand{ .setoption = .{ .name = option_name.?, .value = option_value } };

            } else if (mem.eql(u8, first, "register")) {
                const register_strategy = parts.next();
                std.debug.assert(register_strategy != null);

                
                if (mem.eql(u8, register_strategy.?, "later")) {
                    return GuiToEngineCommand{ .register = .later };
                }

                var payload: struct { name: ?[]const u8, code: ?[]const u8 } = .{
                    .name = null,
                    .code = null,
                };

                if (mem.eql(u8, register_strategy.?, "name")) {
                    const name_value = parts.next();
                    std.debug.assert(name_value != null);

                    payload.name = name_value;
                } else if (mem.eql(u8, register_strategy.?, "code")) {
                    const code_value = parts.next();
                    std.debug.assert(code_value != null);

                    payload.code = code_value;
                }

                const next_reg_strat = parts.next();
                if (next_reg_strat == null) {
                    // The register command does not require both
                    // name and code to be set. If there's nothing more to parse,
                    // that is legal and we are done here so long as one of the
                    // two options is set.
                    std.debug.assert(payload.code != null or payload.name != null);
                    return GuiToEngineCommand{
                        .register = .{
                            .now = .{
                                .name = payload.name,
                                .code = payload.code
                            }
                        }
                    };
                }

                // Otherwise continue parsing to get the second part of the registration command
                if (mem.eql(u8, next_reg_strat.?, "name")) {
                    const name_value = parts.next();
                    std.debug.assert(name_value != null);

                    payload.name = name_value;
                } else if (mem.eql(u8, next_reg_strat.?, "code")) {
                    const code_value = parts.next();
                    std.debug.assert(code_value != null);

                    payload.code = code_value;
                }

                // Register has a maximum of two subcommands (setting both name & code),
                // so now we're done here no matter what.
                // However, just to be safe, we'll assert that both are set
                // since in theory we could get to this stage parsing input that looks
                // like "register name somename name someothername".
                std.debug.assert(payload.code != null and payload.name != null);
                return GuiToEngineCommand{
                    .register = .{
                        .now = .{
                            .name = payload.name,
                            .code = payload.code
                        }
                    }
                };

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

test "Parsing command from string produces accurate tagged enum from valid command inputs" {
    // uci
    try std.testing.expectEqual(
        .uci,
        UciCommand.GuiToEngineCommand.fromString(&"uci   ignorethis"));

    // debug
    try std.testing.expectEqual(
        UciCommand.GuiToEngineCommand{ .debug = true },
        UciCommand.GuiToEngineCommand.fromString(&"debug on"));

    try std.testing.expectEqual(
        UciCommand.GuiToEngineCommand{ .debug = false },
        UciCommand.GuiToEngineCommand.fromString(&"debug off"));

    try std.testing.expectEqual(
        UciCommand.GuiToEngineCommand{ .debug = false },
        UciCommand.GuiToEngineCommand.fromString(&"debug ignored off ignoredagain"));

    // setopt
    const parsed_setopt_val   = UciCommand.GuiToEngineCommand.fromString(&"setoption name hello value world");
    const expected_setopt_val = UciCommand.GuiToEngineCommand{ .setoption = .{ .name = "hello", .value = "world" } };
    try std.testing.expectEqualStrings(parsed_setopt_val.setoption.name, expected_setopt_val.setoption.name);
    try std.testing.expectEqualStrings(parsed_setopt_val.setoption.value.?, expected_setopt_val.setoption.value.?);

    const parsed_setopt   = UciCommand.GuiToEngineCommand.fromString(&"setoption name hello");
    const expected_setopt = UciCommand.GuiToEngineCommand{ .setoption = .{ .name = "hello", .value = null } };
    try std.testing.expectEqualStrings(expected_setopt.setoption.name, parsed_setopt.setoption.name);
    try std.testing.expectEqual(null, parsed_setopt.setoption.value);

    // register
    const parsed_reg_ltr   = UciCommand.GuiToEngineCommand.fromString(&"register later");
    const expected_reg_ltr = UciCommand.GuiToEngineCommand{ .register = .later };
    try std.testing.expectEqual(expected_reg_ltr, parsed_reg_ltr);

    const parsed_reg_name   = UciCommand.GuiToEngineCommand.fromString(&"register name ligma");
    const expected_reg_name = UciCommand.GuiToEngineCommand { .register = .{ .now = .{ .name = "ligma", .code = null } } };
    try std.testing.expectEqualStrings(parsed_reg_name.register.now.name.?, expected_reg_name.register.now.name.?);
    try std.testing.expectEqual(parsed_reg_name.register.now.code, expected_reg_name.register.now.code);

    const parsed_reg_code   = UciCommand.GuiToEngineCommand.fromString(&"register code 9001");
    const expected_reg_code = UciCommand.GuiToEngineCommand { .register = .{ .now = .{ .name = null, .code = "9001" } } };
    try std.testing.expectEqualStrings(parsed_reg_code.register.now.code.?, expected_reg_code.register.now.code.?);
    try std.testing.expectEqual(parsed_reg_code.register.now.name, expected_reg_code.register.now.name);

    const parsed_reg_both   = UciCommand.GuiToEngineCommand.fromString(&"register code 9001 name ligma");
    const expected_reg_both = UciCommand.GuiToEngineCommand { .register = .{ .now = .{ .name = "ligma", .code = "9001" } } };
    try std.testing.expectEqualStrings(parsed_reg_both.register.now.code.?, expected_reg_both.register.now.code.?);
    try std.testing.expectEqualStrings(parsed_reg_both.register.now.name.?, expected_reg_both.register.now.name.?);
}

