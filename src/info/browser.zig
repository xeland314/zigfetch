const std = @import("std");
const builtin = @import("builtin");
const is_wasm: bool = builtin.target.cpu.arch == .wasm32;

extern "env" fn getBrowserNameLen() u32;
extern "env" fn getBrowserName(ptr: [*]u8) void;
extern "env" fn getLanguageLen() u32;
extern "env" fn getLanguage(ptr: [*]u8) void;
extern "env" fn getResolutionLen() u32;
extern "env" fn getResolution(ptr: [*]u8) void;
extern "env" fn getCpuCores() u32;

pub fn getName(allocator: std.mem.Allocator) []const u8 {
    if (comptime !is_wasm) return "Web Browser";
    const len = getBrowserNameLen();
    const buf = allocator.alloc(u8, len) catch return "Web Browser";
    getBrowserName(buf.ptr);
    return buf;
}

pub fn getSystemLanguage(allocator: std.mem.Allocator) []const u8 {
    if (comptime !is_wasm) return "unknown";
    const len = getLanguageLen();
    const buf = allocator.alloc(u8, len) catch return "unknown";
    getLanguage(buf.ptr);
    return buf;
}

pub fn getScreenResolution(allocator: std.mem.Allocator) []const u8 {
    if (comptime !is_wasm) return "unknown";
    const len = getResolutionLen();
    const buf = allocator.alloc(u8, len) catch return "unknown";
    getResolution(buf.ptr);
    return buf;
}

pub fn getCpuCoreCount() u32 {
    if (comptime !is_wasm) return 0;
    return getCpuCores();
}

