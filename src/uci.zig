const std = @import("std");
const mem = std.mem;


// This section is based on the specification of the UCI protocol
// described at https://gist.github.com/DOBRO/2592c6dad754ba67e6dcaec8c90165bf


pub const Uci = enum {
    /// Command from the GUI to the engine
    pub const EngineCommand = union(enum) {
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
        /// Start calculating on the current position set up with the "position" command
        go: struct {
            /// Restrict search to these moves only
            // TODO - Consider updating type once we have solidified an approach
            //        to parsing FEN moves into something typesafe & descriptive
            searchmoves: ?[][]const u8,

            /// Start searching in pondering mode.
            /// I don't understand the specification on this one.
            ponder: bool,
            
            /// White has <value> milliseconds left on the clock.
            /// TODO - Determine appropriate level of precision, could this be 16 bits instead?
            wtime: ?u32,

            /// Black has <value> milliseconds left on the clock.
            /// TODO - Determine appropriate level of precision, could this be 16 bits instead?
            btime: ?u32,

            /// White increment per move in milliseconds if <value> > 0
            winc: ?u32,

            /// Black increment per move in milliseconds if <value> > 0
            binc: ?u32,

            /// There are <value> moves to the next time control.
            /// If present at all, <value> > 0.
            /// If this is not received, but wtime and btime are received,
            /// it's sudden death.
            movestogo: ?u8,

            /// Search <value> plies only
            depth: ?u16,

            /// Search <value> nodes only
            nodes: ?u16,

            /// Search for a mate in <value> moves
            mate: ?u16,

            /// Search exactly <value> milliseconds
            movetime: ?u32,

            /// Search until the stop command. If this is present (`true`),
            /// do not exit search unless the `stop` command is received.
            infinite: bool,
        },
        stop,
        ponderhit,
        quit,

        const This = @This();

        const ParseError = error {
            NotACommand,
            IllegalCommandState,
            IntegerParseError,
            Unimplemented
        };

        /// Parse a string literal into a command from the GUI to the engine, including
        /// the command's payload.
        /// Current behavior is to **crash** on unparseable command strings, since at this
        /// stage all bugs should be assumed to originate from this codebase rather than from
        /// the UI.
        // TODO - Don't crash on bad commands once this implementation is reasonably stable.
        // TODO - All the string comparison here is surely expensive, figure out if it is
        //        actually unavoidable.
        pub fn fromString(str: *const []const u8) ParseError!EngineCommand {
            // TODO - It's probably unlikely but what if a UI is devious enough
            //        to use a tab character as its delimiter?
            var parts = mem.splitScalar(u8, str.*, ' ');

            const first = parts.first();

            if (mem.eql(u8, first, "uci")) {
                return .uci;

            } else if (mem.eql(u8, first, "debug")) {
                while (parts.next()) |option| {
                    if (mem.eql(u8, option, "on")) {
                        return EngineCommand{ .debug = true };
                    } else if (mem.eql(u8, option, "off")) {
                        return EngineCommand{ .debug = false };
                    }
                }

                return ParseError.IllegalCommandState;

            } else if (mem.eql(u8, first, "isready")) {
                return .isready;

            } else if (mem.eql(u8, first, "setoption")) {
                const name_label = parts.next();

                if (name_label != null and !mem.eql(u8, name_label.?, "name")) {
                    return ParseError.IllegalCommandState;
                }

                const option_name = parts.next();
                if (option_name == null) {
                    return ParseError.IllegalCommandState;
                }

                const value_label = parts.next();
                if (value_label == null) {
                    // If there's no value, then the command is complete
                    // and we can be finished
                    return EngineCommand{ .setoption = .{ .name = option_name.?, .value = null } };
                }

                // otherwise, continue parsing to get the value for the
                // option being set
                if (!mem.eql(u8, value_label.?, "value")) {
                    return ParseError.IllegalCommandState;
                }

                const option_value = parts.next();
                if (option_value == null) {
                    return ParseError.IllegalCommandState;
                }

                return EngineCommand{ .setoption = .{ .name = option_name.?, .value = option_value } };

            } else if (mem.eql(u8, first, "register")) {
                const register_strategy = parts.next();
                if (register_strategy == null) {
                    return ParseError.IllegalCommandState;
                }
                
                if (mem.eql(u8, register_strategy.?, "later")) {
                    return EngineCommand{ .register = .later };
                }

                var payload: struct { name: ?[]const u8, code: ?[]const u8 } = .{
                    .name = null,
                    .code = null,
                };

                if (mem.eql(u8, register_strategy.?, "name")) {
                    const name_value = parts.next();
                    if (name_value == null) {
                        return ParseError.IllegalCommandState;
                    }

                    payload.name = name_value;

                } else if (mem.eql(u8, register_strategy.?, "code")) {
                    const code_value = parts.next();
                    if (code_value == null) {
                        return ParseError.IllegalCommandState;
                    }

                    payload.code = code_value;
                }

                const next_reg_strat = parts.next();
                if (next_reg_strat == null) {
                    // The register command does not require both
                    // name and code to be set. If there's nothing more to parse,
                    // that is legal and we are done here so long as one of the
                    // two options is set.
                    if (payload.name != null or payload.code != null) {
                        return EngineCommand{
                            .register = .{
                                .now = .{
                                    .name = payload.name,
                                    .code = payload.code
                                }
                            }
                        };
                    }
                }

                // Otherwise continue parsing to get the second part of the registration command
                if (mem.eql(u8, next_reg_strat.?, "name")) {
                    const name_value = parts.next();
                    if (name_value == null) {
                        return ParseError.IllegalCommandState;
                    }

                    payload.name = name_value;

                } else if (mem.eql(u8, next_reg_strat.?, "code")) {
                    const code_value = parts.next();
                    if (code_value == null) {
                        return ParseError.IllegalCommandState;
                    }

                    payload.code = code_value;
                }

                // Register has a maximum of two subcommands (setting both name & code),
                // so now we're done here no matter what.
                // However, just to be safe, we'll assert that both are set
                // since in theory we could get to this stage parsing input that looks
                // like "register name somename name someothername".
                if (payload.code == null or payload.name == null) {
                    return ParseError.IllegalCommandState;
                }

                return EngineCommand{
                    .register = .{
                        .now = .{
                            .name = payload.name,
                            .code = payload.code
                        }
                    }
                };

            } else if (mem.eql(u8, first, "ucinewgame")) {
                return .ucinewgame;

            } else if (mem.eql(u8, first, "position")) {
                // TODO - This is going to be a lot and will involve parsing FEN position strings.
                //        I'll do this one last.
                return ParseError.Unimplemented;

            } else if (mem.eql(u8, first, "go")) {
                // Extract the type of the payload
                const GoPayload = @TypeOf(@as(Uci.EngineCommand, undefined).go);

                var payload: GoPayload = .{
                    .searchmoves = null,
                    .ponder = false,
                    .wtime = null,
                    .btime = null,
                    .winc = null,
                    .binc = null,
                    .movestogo = null,
                    .depth = null,
                    .nodes = null,
                    .mate = null,
                    .movetime = null,
                    .infinite = false,
                };

                // This command has lots of subcommands, many of which require parsing
                // strings into integers.
                while (parts.next()) |subcmd| {
                    if (mem.eql(u8, subcmd, "searchmoves")) {
                        return ParseError.Unimplemented;

                    } else if (mem.eql(u8, subcmd, "ponder")) {
                        payload.ponder = true;

                    } else if (mem.eql(u8, subcmd, "wtime")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u32, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.wtime = parsed;

                    } else if (mem.eql(u8, subcmd, "btime")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u32, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.btime = parsed;

                    } else if (mem.eql(u8, subcmd, "winc")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u32, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.winc = parsed;

                    } else if (mem.eql(u8, subcmd, "binc")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u32, value.?, 10)
                            catch return ParseError.IntegerParseError;

                        payload.binc = parsed;

                    } else if (mem.eql(u8, subcmd, "movestogo")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u8, value.?, 10)
                            catch return ParseError.IntegerParseError;

                        payload.movestogo = parsed;

                    } else if (mem.eql(u8, subcmd, "depth")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u16, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.depth = parsed;

                    } else if (mem.eql(u8, subcmd, "nodes")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u16, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.nodes = parsed;

                    } else if (mem.eql(u8, subcmd, "mate")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u16, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.mate = parsed;

                    } else if (mem.eql(u8, subcmd, "movetime")) {
                        const value = parts.next();
                        if (value == null) {
                            return ParseError.IllegalCommandState;
                        }

                        const parsed = std.fmt.parseUnsigned(u32, value.?, 10)
                            catch return ParseError.IntegerParseError;
                        payload.movetime = parsed;

                    } else if (mem.eql(u8, subcmd, "infinite")) {
                        payload.infinite = true;
                    }
                }

                return EngineCommand{ .go = payload };

            } else if (mem.eql(u8, first, "stop")) {
                return .stop;

            } else if (mem.eql(u8, first, "ponderhit")) {
                return .ponderhit;

            } else if (mem.eql(u8, first, "quit")) {
                return .quit;
            }

            return ParseError.NotACommand;
        }
    };

    /// Command from the engine to the GUI
    pub const GuiCommand = union(enum) {
        id: union(enum) {
            name: []const u8,
            author: []const u8,
        },
        uciok,
        readyok,
        bestmove: struct {
            // TODO - Type for move notation
            move1: []const u8,
            move2: ?[]const u8,
        },
        // These two are unimplemented for now
        copyprotection,
        registration,

        info: union(enum) {
            /// Search depth in plies
            depth: u16,

            /// Selective search depth in plies.
            /// If this command is present, a "depth" command must be present in the same payload.
            seldepth: u16,

            /// Time searched in milliseconds.
            /// Should accompany the `pv` attribute in payload.
            time: u32,

            /// Number of nodes searched, engine should send this info regularly.
            nodes: u32,

            /// The best line found
            pv: [][]const u8, // TODO - Type for move notation

            // TODO - What the hell does this mean?
            /// For multi-pv mode.
            /// For the best move/pv, add "multipv 1" in the string when `pv` is sent.
            /// In k-best mode always send all k variants in k strings together
            multipv: u32,

            score: union(enum) {
                /// Score from engine's POV in units of centipawns.
                cp: u32,

                /// Mate in <value> moves (unit is moves, not plies).
                /// If the engine is getting mated, uses negative values for <value>.
                mate: i16,

                // TODO - Is bool correct type for this?
                /// If the score is just a lower bound.
                lowerbound: bool,

                // TODO - Is bool correct type for this?
                /// If the score is just an upper bound.
                upperbound: bool,
            },

            /// Currently searching this move.
            currmove: []const u8, // TODO - Notation for moves

            /// Currently search move number <value>, where the first move has <value> 1 (not 0).
            currmovenumber: i32,

            // TODO - What does this mean? Is "permill" per-million? Per-million what?
            /// The hash is <value> permill full, the engine should send this info regularly.
            hashfull: u32,

            /// <value> nodes per second searched, engine should send this info regularly.
            nps: u32, // TODO - Might need a bigger integer here

            /// <value> positions were found in the endgame table databases.
            tbhits: u32,

            /// <value> positions were found in the shredder endgame databses.
            sbhits: u32,

            // TODO - How is this statistic calculated?
            /// The CPU usage of the engine is <value> permill (per-million?)
            cpuload: u64,

            /// Any string <value> which will be displayed (by the UI?)
            string: []const u8,

            /// Move <value1> is refuted by the line <value2> - <value{i}>, where `i` can
            /// be any number >= 1.
            /// If there is no refutation for <value1>, the command should be sent as
            /// `info refutation <value1>`.
            refutation: [][]const u8, // TODO - Type for move notation

            /// This is the current line the engine is calculating.
            currline: struct {
                /// The number of CPUs the engine is running on.
                /// If running on 1 CPU, this parameter can be omitted.
                cpunr: ?u8,

                /// The line the engine is calculating.
                moves: [][]const u8, // TODO - Type for move notation
            },
        },
        /// Tells the GUI which parameters can be changed in the engine.
        /// This should be sent once at engine startup after the "uci" and "id" commands
        /// if any parameter can be changed in the engine.
        option: union(enum) {
            // For now, nothing is parameterized.
        }
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

        /// Check the input stream for new commands.
        /// If no input is present, return `null`.
        /// If an input is present, attempt to parse it and returned the parsed command, or an error.
        pub fn poll(self: *@This()) !?Uci.EngineCommand {
            var buf: [128]u8 = undefined;
            const input = try self.input_stream.readUntilDelimiterOrEof(&buf, '\n');

            if (input == null) {
                return null;
            }

            const command = Uci.EngineCommand.fromString(&input.?) catch |err| {
                std.debug.print("Could not parse command: {}\n", .{err});
                return null;
            };

            return command;
        }

        const CommandSendError = error{ };
        /// Send the given command to the output stream.
        /// Return an error if the output could not be sent.
        pub fn send(self: *@This(), command: Uci.GuiCommand) !void {
            var bw = std.io.bufferedWriter(self.output_stream);
            const output = bw.writer();

            defer bw.flush() catch unreachable;

            switch (command) {
                .id => |subcommand| {
                    switch (subcommand) {
                        .author => |author| {
                            try output.print("id author {s}\n", .{ author });
                        },
                        .name => |name| {
                            try output.print("id name {s}\n", .{ name });
                        },
                    }
                },
                .uciok => {
                    try output.print("uciok\n", .{});
                },
                .readyok => {
                    try output.print("readyok\n", .{});
                },
                .bestmove => |moves| {
                    if (moves.move2 != null) {
                        try output.print("bestmove {s} ponder {s}\n", .{ moves.move1, moves.move2.? });
                    } else {
                        try output.print("bestmove {s}\n", .{ moves.move1 });
                    }
                },
                .copyprotection => {
                    // FIXME
                    unreachable;
                },
                .registration => {
                    // FIXME
                    unreachable;
                },
                .info => |info| {
                    switch (info) {
                        .depth => |plies| {
                            _ = plies;
                        },
                        .seldepth => |plies| {
                            _ = plies;
                        },
                        .time => |millis| {
                            _ = millis;
                        },
                        .nodes => |number| {
                            _ = number;
                        },
                        .pv => |line| {
                            _ = line;
                        },
                        .multipv => |number| {
                            _ = number;
                        },
                        .score => |score| {
                            switch (score) {
                                .cp => |centipawns| {
                                    _ = centipawns;
                                },
                                .mate => |number| {
                                    _ = number;
                                },
                                .lowerbound => |number| {
                                    _ = number;
                                },
                                .upperbound => |number| {
                                    _ = number;
                                }
                            }
                        },
                        .currmove => |move| {
                            _ = move;

                        },
                        .currmovenumber => |number| {
                            _ = number;

                        },
                        .hashfull => |permill| {
                            _ = permill;

                        },
                        .nps => |nodes_per_sec| {
                            _ = nodes_per_sec;
                        },
                        .tbhits => |number| {
                            _ = number;
                        },
                        .sbhits => |number| {
                            _ = number;

                        },
                        .cpuload => |permill| {
                            _ = permill;

                        },
                        .string => |str| {
                            _ = str;

                        },
                        .refutation => |moves| {
                            _ = moves;

                        },
                        .currline => |payload| {
                            _ = payload;
                        },
                    }
                },
                .option => |option| {
                    // TODO
                    _ = option;
                },
            }
        }
    };
}

test "Parses string 'uci' into command" {
    try std.testing.expectEqual(
        .uci,
        Uci.EngineCommand.fromString(&"uci   ignorethis"));
}

test "Parses 'debug on' command correctly" {
    try std.testing.expectEqual(
        Uci.EngineCommand{ .debug = true },
        Uci.EngineCommand.fromString(&"debug on"));
}

test "Parses 'debug off' command correctly" {
    try std.testing.expectEqual(
        Uci.EngineCommand{ .debug = false },
        Uci.EngineCommand.fromString(&"debug off"));
}

test "Debug command without valid option returns error" {
    const Err = Uci.EngineCommand.ParseError;
    try std.testing.expectEqual(
        Err.IllegalCommandState,
        Uci.EngineCommand.fromString(&"debug \t junk"));
}

test "Ignores extra tokens in otherwise valid 'debug' command" {
    try std.testing.expectEqual(
        Uci.EngineCommand{ .debug = false },
        Uci.EngineCommand.fromString(&"debug ignored off ignoredagain"));
}

test "Parses 'setoption' command with name and value" {
    const parsed = try Uci.EngineCommand.fromString(&"setoption name hello value world");
    const expected = Uci.EngineCommand{ .setoption = .{ .name = "hello", .value = "world" } };
    try std.testing.expectEqualStrings(expected.setoption.name, parsed.setoption.name);
    try std.testing.expectEqualStrings(expected.setoption.value.?, parsed.setoption.value.?);
}

test "Parses 'setoption' command with name only" {
    const parsed = try Uci.EngineCommand.fromString(&"setoption name hello");
    const expected = Uci.EngineCommand{ .setoption = .{ .name = "hello", .value = null } };
    try std.testing.expectEqualStrings(expected.setoption.name, parsed.setoption.name);
    try std.testing.expectEqual(null, parsed.setoption.value);
}

test "'setoption' with 'value' option but no actual value produces error" {
    const Err = Uci.EngineCommand.ParseError;
    const parsed = Uci.EngineCommand.fromString(&"setoption value  \t  ");
    const expected = Err.IllegalCommandState;
    try std.testing.expectEqual(expected, parsed);
}

test "'setoption' without 'name' subcommand produces error" {
    const Err = Uci.EngineCommand.ParseError;
    const parsed = Uci.EngineCommand.fromString(&"setoption value 98000");
    const expected = Err.IllegalCommandState;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'register later' command" {
    const parsed = try Uci.EngineCommand.fromString(&"register later");
    const expected = Uci.EngineCommand{ .register = .later };
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'register name' command" {
    const parsed = try Uci.EngineCommand.fromString(&"register name ligma");
    const expected = Uci.EngineCommand{ .register = .{ .now = .{ .name = "ligma", .code = null } } };
    try std.testing.expectEqualStrings(expected.register.now.name.?, parsed.register.now.name.?);
    try std.testing.expectEqual(expected.register.now.code, parsed.register.now.code);
}

test "Parses 'register code' command" {
    const parsed = try Uci.EngineCommand.fromString(&"register code 9001");
    const expected = Uci.EngineCommand{ .register = .{ .now = .{ .name = null, .code = "9001" } } };
    try std.testing.expectEqualStrings(expected.register.now.code.?, parsed.register.now.code.?);
    try std.testing.expectEqual(expected.register.now.name, parsed.register.now.name);
}

test "Parses 'register code and name' command" {
    const parsed = try Uci.EngineCommand.fromString(&"register code 9001 name ligma");
    const expected = Uci.EngineCommand{ .register = .{ .now = .{ .name = "ligma", .code = "9001" } } };
    try std.testing.expectEqualStrings(expected.register.now.code.?, parsed.register.now.code.?);
    try std.testing.expectEqualStrings(expected.register.now.name.?, parsed.register.now.name.?);
}

test "Register command with no value, code, or later returns error" {
    const Err = Uci.EngineCommand.ParseError;
    const parsed = Uci.EngineCommand.fromString(&"register no this will not do");
    const expected =  Err.IllegalCommandState;
    try std.testing.expectEqual(expected, parsed);
}

test "Register command with code but no value returns error" {
    const Err = Uci.EngineCommand.ParseError;
    const parsed = Uci.EngineCommand.fromString(&"register code");
    const expected =  Err.IllegalCommandState;
    try std.testing.expectEqual(expected, parsed);
}

test "Register command with multiple instances of name but no code returns error" {
    const Err = Uci.EngineCommand.ParseError;
    const parsed = Uci.EngineCommand.fromString(&"register name something name something else");
    const expected =  Err.IllegalCommandState;
    try std.testing.expectEqual(expected, parsed);
}

test "Register command with name but no value returns error" {
    const Err = Uci.EngineCommand.ParseError;
    const parsed = Uci.EngineCommand.fromString(&"register name");
    const expected =  Err.IllegalCommandState;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'ucinewgame' command and ignores extra tokens" {
    try std.testing.expectEqual(.ucinewgame,
    try Uci.EngineCommand.fromString(&"ucinewgame ignored ignoredagain"));
}

// TODO - Tests for 'position'

test "Parses 'go' command with no subcommands" {
    const parsed = try Uci.EngineCommand.fromString(&"go");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go ponder' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go ponder");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = true,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go wtime' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go wtime helloworld!");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go wtime' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go wtime 5000");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = 5000,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go btime' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go btime helloworld!");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go btime' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go btime 4000");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = 4000,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go winc' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go winc 300");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = 300,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go winc' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go winc helloworld!");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go binc' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go binc 300");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = 300,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go binc' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go binc helloworld!");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go movestogo' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go movestogo 30");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = 30,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go movestogo' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go movestogo thirty");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go depth' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go depth 10");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = 10,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go depth' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go depth ten");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go nodes' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go nodes 10000");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = 10000,
            .mate = null,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go nodes' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go nodes ten");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go mate' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go mate 3");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = 3,
            .movetime = null,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go mate' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go mate 9thousand");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go movetime' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go movetime 1000");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = 1000,
            .infinite = false,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "'go movetime' command that provides non-integer value returns error" {
    const parsed = Uci.EngineCommand.fromString(&"go movetime 9thousand");
    const Err = Uci.EngineCommand.ParseError;
    const expected = Err.IntegerParseError;
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go infinite' command" {
    const parsed = try Uci.EngineCommand.fromString(&"go infinite");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = null,
            .btime = null,
            .winc = null,
            .binc = null,
            .movestogo = null,
            .depth = null,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = true,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

test "Parses 'go' command with multiple parameters" {
    const parsed = try Uci.EngineCommand.fromString(&"go wtime 5000 btime 4000 winc 100 binc 100 depth 8 infinite");
    const expected = Uci.EngineCommand{
        .go = .{
            .searchmoves = null,
            .ponder = false,
            .wtime = 5000,
            .btime = 4000,
            .winc = 100,
            .binc = 100,
            .movestogo = null,
            .depth = 8,
            .nodes = null,
            .mate = null,
            .movetime = null,
            .infinite = true,
        }
    };
    try std.testing.expectEqual(expected, parsed);
}

// TODO - Test `go searchmoves` when that is implemented

test "Parses 'stop' command" {
    try std.testing.expectEqual(.stop, try Uci.EngineCommand.fromString(&"stop"));
}

test "Parses 'ponderhit' command" {
    try std.testing.expectEqual(.ponderhit, try Uci.EngineCommand.fromString(&"ponderhit"));
}

test "Parses 'quit' command" {
    try std.testing.expectEqual(.quit, try Uci.EngineCommand.fromString(&"quit"));
}

test "Omitting required subcommand returns an error" {
    const Err = Uci.EngineCommand.ParseError;
    const result = Uci.EngineCommand.fromString(&"setoption notname");
    try std.testing.expectEqual(Err.IllegalCommandState, result);
}

test "Input that doesn't match a command returns an error" {
    const Err = Uci.EngineCommand.ParseError;
    const result = Uci.EngineCommand.fromString(&"nothing");
    try std.testing.expectEqual(Err.NotACommand, result);
}

