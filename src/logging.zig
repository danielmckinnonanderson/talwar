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
    
    pub fn printerr(self: *Self, comptime message: []const u8) !void {
        try self.logMessage("ERROR", message);
    }
    
    pub fn warn(self: *Self, comptime message: []const u8) !void {
        if (@intFromEnum(self.level) >= @intFromEnum(LogLevel.warn)) {
            try self.logMessage("WARN", message);
        }
    }
    
    pub fn info(self: *Self, comptime message: []const u8) !void {
        if (@intFromEnum(self.level) >= @intFromEnum(LogLevel.info)) {
            try self.logMessage("INFO", message);
        }
    }
    
    pub fn debug(self: *Self, comptime message: []const u8) !void {
        if (@intFromEnum(self.level) >= @intFromEnum(LogLevel.debug)) {
            try self.logMessage("DEBUG", message);
        }
    }

    inline fn logMessage(self: *Self, log_level: []const u8, comptime message: []const u8) !void {
        const timestamp = std.time.timestamp();
        try self.writer.print("{d} [{s}]: \"{s}\"", .{timestamp, log_level, message});
    }
};

