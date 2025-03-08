const std = @import("std");
const bitboards = @import("./bitboards.zig");
const uci = @import("./uci.zig");

pub fn main() !void {
    // const interface = uci.Interface {};
    const b = bitboards.Board.init();
    std.debug.print("{}\n", .{b});


    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Enter text of any length, then press ENTER.", .{});

    // Method: Process input in chunks without an allocator
    {
        const chunk_size = 128; // Size of each chunk to read
        var buffer: [chunk_size]u8 = undefined;
        var total_bytes_read: usize = 0;
        
        // Process the input in chunks
        while (true) {
            // Try to read a chunk
            const bytes_read = try stdin.readUntilDelimiterOrEof(&buffer, '\n') orelse break;
            total_bytes_read += bytes_read.len;
            
            // Process this chunk immediately
            try processChunk(bytes_read, stdout);
            
            // Check if we reached the end of a line
            if (bytes_read.len < chunk_size or 
                (bytes_read.len > 0 and bytes_read[bytes_read.len - 1] == '\n')) {
                break;
            }
        }
        
        try stdout.print("\nTotal bytes processed: {d}\n", .{total_bytes_read});
    }
}

// Function to process each chunk of data
fn processChunk(chunk: []const u8, writer: anytype) !void {
    // Example processing: Count and print uppercase letters
    var uppercase_count: usize = 0;
    
    for (chunk) |char| {
        if (char >= 'A' and char <= 'Z') {
            uppercase_count += 1;
        }
    }
    
    try writer.print("Chunk size: {d}, Uppercase letters: {d}, Content: {s}\n", 
                    .{chunk.len, uppercase_count, chunk});
}
