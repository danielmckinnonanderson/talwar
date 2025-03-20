const std = @import("std");

pub const LogLevel = enum { debug, info, warn, err };

pub const Logger = struct {
    level: LogLevel = .info,
    file: std.fs.File,
    writer: std.fs.File.Writer,

    const Self = @This();
    
    pub fn init(log_path: []const u8, comptime log_level: LogLevel) !Self {
        const file = try std.fs.cwd().createFile(log_path, .{});
        
        return Self {
            .level = log_level,
            .file = file,
            .writer = file.writer(),
        };
    }
    
    pub fn deinit(self: *Self) void {
        self.file.close();
    }
    
    pub fn printerr(self: *Self, comptime fmt: []const u8, arg: anytype) !void {
        try self.logMessage("ERROR", fmt, arg);
    }
    
    pub fn warn(self: *Self, comptime fmt: []const u8, arg: anytype) !void {
        if (@intFromEnum(self.level) >= @intFromEnum(LogLevel.warn)) {
            try self.logMessage("WARN", fmt, arg);
        }
    }
    
    pub fn info(self: *Self, comptime fmt: []const u8, arg: anytype) !void {
        if (@intFromEnum(self.level) >= @intFromEnum(LogLevel.info)) {
            try self.logMessage("INFO", fmt, arg);
        }
    }
    
    pub fn debug(self: *Self, comptime fmt: []const u8, arg: anytype) !void {
        if (@intFromEnum(self.level) >= @intFromEnum(LogLevel.debug)) {
            try self.logMessage("DEBUG", fmt, arg);
        }
    }

    inline fn logMessage(self: *Self, log_level: []const u8, comptime fmt: []const u8, arg: anytype) !void {
        try self.writer.print("{s}: \"", .{log_level});
        try self.writer.print(fmt, arg);
        try self.writer.print("\"\n", .{});
    }
};

