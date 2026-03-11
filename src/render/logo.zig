// src/render/logo.zig
const std = @import("std");

pub fn printColorPalette(writer: anytype, bright: bool) void {
    const base = if (bright) @as(u8, 100) else @as(u8, 40);
    var i: u8 = 0;
    while (i < 8) : (i += 1) {
        writer.print("\x1b[{d}m  ", .{base + i}) catch {};
    }
    _ = writer.write("\x1b[0m") catch {};
}
