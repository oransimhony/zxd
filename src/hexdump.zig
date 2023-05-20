//! A module containing functions for printing a HexDump of given bytes.
//! This module supports printing in color if the underlying TTY supports it.
const std = @import("std");

/// The number of bytes dumped in one line.
pub const BYTES_IN_LINE: usize = 16;

const ADDRESS_PRINTING_LENGTH: usize = 8;
const BYTE_PRINTING_LENGTH: usize = 2;

const NUMBER_OF_SPACES_IN_LINE: usize = 8;
const NUMBER_OF_BYTES_BEFORE_SPACE: usize = 2;

/// Section Seperator can be changed but must not be more than two bytes in length.
const sectionSeperator = "|";
comptime {
    std.debug.assert(sectionSeperator.len <= 2);
}

/// Address + "0x" + ":"
/// 8 + 2 + 1 = 11
const ADDRESS_SECTION_LENGTH = ADDRESS_PRINTING_LENGTH + 2 + 1;

/// Bytes + Spaces between bytes + space before the bytes (the space after is counter in NUMBER_OF_SPACES_IN_LINE)
/// 16 * 2 + 8 + 1 = 32 + 8 + 1 = 41
const HEX_CONTENTS_SECTION_LENGTH = BYTES_IN_LINE * BYTE_PRINTING_LENGTH + NUMBER_OF_SPACES_IN_LINE + 1;

/// Bytes in their text form + the section seperator twice
/// 16 + 2 * sectionSeperator.len
const TEXT_CONTENTS_SECTION_LENGTH = BYTES_IN_LINE + 2 * sectionSeperator.len;

const TOTAL_LENGTH = ADDRESS_SECTION_LENGTH + HEX_CONTENTS_SECTION_LENGTH + TEXT_CONTENTS_SECTION_LENGTH;

const stdout = std.io.getStdOut();
const writer = stdout.writer();

const Color = std.debug.TTY.Color;
const addressColor = Color.Green;
const printableColor = Color.Yellow;
const nonPrintableColor = Color.Cyan;
const filePathColor = Color.Yellow;

var tty_config: ?std.debug.TTY.Config = null;
var currentColor = std.debug.TTY.Color.Reset;

fn printColor(color: std.debug.TTY.Color) !void {
    if (color == currentColor) {
        return;
    }

    if (tty_config == null) {
        tty_config = std.debug.detectTTYConfig(stdout);
    }

    try tty_config.?.setColor(writer, color);
    currentColor = color;
}

fn printHexDumpHeader(offset: usize) !void {
    try printColor(addressColor);
    const fmt = std.fmt.comptimePrint("0x{{x:0>{}}}: ", .{ADDRESS_PRINTING_LENGTH});
    try writer.print(fmt, .{offset});
    try printColor(.Reset);
}

fn printHexDumpBody(contents: []const u8) !void {
    for (contents, 0..) |byte, i| {
        var non_printable = !std.ascii.isPrint(byte);
        if (non_printable) {
            try printColor(nonPrintableColor);
        } else {
            try printColor(printableColor);
        }
        const fmt = std.fmt.comptimePrint("{{x:0>{}}}", .{BYTE_PRINTING_LENGTH});
        try writer.print(fmt, .{byte});
        try printColor(.Reset);
        if (i % NUMBER_OF_BYTES_BEFORE_SPACE == (NUMBER_OF_BYTES_BEFORE_SPACE - 1)) {
            _ = try writer.write(" ");
        }
    }
}

fn printHexDumpTrailer(contents: []const u8) !void {
    // Add padding before Text Contents Section
    if (contents.len < BYTES_IN_LINE) {
        const padding_length = (BYTES_IN_LINE - contents.len) * BYTE_PRINTING_LENGTH + (NUMBER_OF_SPACES_IN_LINE - (contents.len / NUMBER_OF_BYTES_BEFORE_SPACE));
        try writer.writeByteNTimes(' ', padding_length);
    }

    _ = try writer.write(sectionSeperator);
    for (contents) |byte| {
        if (std.ascii.isPrint(byte)) {
            try printColor(printableColor);
            try writer.print("{c}", .{byte});
        } else {
            try printColor(nonPrintableColor);
            _ = try writer.write(".");
        }
        try printColor(.Reset);
    }

    // Add padding before the closing of Text Contents Section
    if (contents.len < BYTES_IN_LINE) {
        const padding_length = BYTES_IN_LINE - contents.len;
        try writer.writeByteNTimes(' ', padding_length);
    }
    _ = try writer.write(sectionSeperator);
    _ = try writer.write("\n");
}

/// Prints a file path in a format that matches the HexDump table.
pub fn printFilePath(path: []const u8) !void {
    try printColor(.Bold);
    const formatted = std.fmt.comptimePrint("{s} File Path: ", .{sectionSeperator});
    _ = try writer.write(formatted);
    try printColor(filePathColor);
    const fmt = std.fmt.comptimePrint("{{s: <{}}}", .{TOTAL_LENGTH - formatted.len - 1 - sectionSeperator.len});
    try writer.print(fmt, .{path});
    try printColor(.Reset);
    try printColor(.Bold);
    _ = try writer.print(" {s}\n", .{sectionSeperator});
    try printColor(.Reset);
}

/// Prints a breakdown of the different fields in the hexdump.
pub fn printTableHeader() !void {
    try printColor(.Bold);
    const fmt = std.fmt.comptimePrint("{0s}{{s: <{1}}}{0s}{{s: ^{2}}}{0s}{{s: >{3}}}{0s}\n", .{ sectionSeperator, ADDRESS_SECTION_LENGTH - 2 * sectionSeperator.len, HEX_CONTENTS_SECTION_LENGTH, TEXT_CONTENTS_SECTION_LENGTH - 2 * sectionSeperator.len });
    try writer.print(fmt, .{ "Address", "Hex Contents", "Text Contents" });
    try printColor(.Reset);
}

fn printHexDumpLine(offset: usize, index: usize, contents: []const u8) !void {
    const last_index = std.math.min(index + BYTES_IN_LINE, contents.len);
    const current_body = contents[index..last_index];

    try printHexDumpHeader(offset + index);
    try printHexDumpBody(current_body);
    try printHexDumpTrailer(current_body);
}

/// Prints a hexdump of the provided contents, user can specify the offset in the file.
pub fn printHexDump(offset: usize, contents: []const u8) !void {
    var index: usize = 0;
    while (index < contents.len) : (index += BYTES_IN_LINE) {
        try printHexDumpLine(offset, index, contents);
    }
}