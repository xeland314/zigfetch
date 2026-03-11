// src/info/os.zig
const std = @import("std");

pub fn getLinuxOSName(allocator: std.mem.Allocator) ![]const u8 {
    const file = std.fs.openFileAbsolute("/etc/os-release", .{}) catch return "Linux";
    defer file.close();
    const content = try file.readToEndAlloc(allocator, 4096);
    var lines = std.mem.tokenizeAny(u8, content, "\n\r");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "PRETTY_NAME=")) {
            var val = line[12..];
            if (val.len > 0 and val[0] == '"') val = val[1 .. val.len - 1];
            return val;
        }
    }
    return "Linux";
}
