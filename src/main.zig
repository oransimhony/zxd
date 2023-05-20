const std = @import("std");
const hexdump = @import("hexdump.zig");
const BUF_SIZE: usize = 16 * 4096;

fn printFile(path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    try hexdump.printFilePath(path);
    try hexdump.printTableHeader();

    var index: usize = 0;
    var buf: [BUF_SIZE]u8 = undefined;
    var bytes_read = try file.readAll(&buf);
    while (bytes_read >= buf.len) {
        index += bytes_read;
        try hexdump.printHexDump(index, buf[0..bytes_read]);
        bytes_read = try file.readAll(&buf);
    }

    index += bytes_read;
    try hexdump.printHexDump(index, buf[0..bytes_read]);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var args = try std.process.argsWithAllocator(allocator);

    const skipped = args.skip();
    std.debug.assert(skipped);

    while (args.next()) |arg| {
        try printFile(arg);
    }
    try hexdump.printTableHeader();
}
