const std = @import("std");
const hexdump = @import("hexdump.zig");

const BUF_SIZE: usize = hexdump.BYTES_IN_LINE * 256;

const writer = std.io.getStdErr().writer();

fn printFile(path: []const u8) !void {
    var file: std.fs.File = undefined;
    if (std.mem.eql(u8, path, hexdump.STDIN_PATH)) {
        file = std.io.getStdIn();
    } else {
        file = try std.fs.cwd().openFile(path, .{});
    }
    defer file.close();

    try hexdump.printFilePath(path);
    try hexdump.printTableHeader();

    var index: usize = 0;
    var buf: [BUF_SIZE]u8 = undefined;
    var bytes_read = try file.readAll(&buf);
    while (bytes_read >= buf.len) {
        try hexdump.printHexDump(index, buf[0..bytes_read]);
        index += bytes_read;
        bytes_read = try file.readAll(&buf);
    }

    try hexdump.printHexDump(index, buf[0..bytes_read]);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var args = try std.process.argsWithAllocator(allocator);

    const did_skip = args.skip();
    std.debug.assert(did_skip);

    while (args.next()) |arg| {
        printFile(arg) catch |err| {
            try writer.print("Cannot print file {s}: Got error {s}\n", .{ arg, @errorName(err) });
            // Skip printing the table header if failed to print the file.
            continue;
        };
        // Also print it as the last thing in the output, to help the user notice the different parts.
        hexdump.printTableHeader() catch {};
    }
}
