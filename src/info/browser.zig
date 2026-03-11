// src/info/browser.zig
const std = @import("std");
const builtin = @import("builtin");
const is_wasm = builtin.target.cpu.arch == .wasm32;

extern "env" fn getBrowserNameLen() u32;
extern "env" fn getBrowserName(ptr: [*]u8) void;

pub fn getName(allocator: std.mem.Allocator) []const u8 {
    if (comptime !is_wasm) return "Web Browser";
    const len = getBrowserNameLen();
    const buf = allocator.alloc(u8, len) catch return "Web Browser";
    getBrowserName(buf.ptr);
    return buf;
}

