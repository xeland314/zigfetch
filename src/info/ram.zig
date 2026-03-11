// src/info/ram.zig
const std = @import("std");
const builtin = @import("builtin");

const is_wasm = builtin.target.cpu.arch == .wasm32;

// Solo se compila en Linux
const sysinfo_t = if (!is_wasm) extern struct {
    uptime: i64,
    loads: [3]u64,
    totalram: u64,
    freeram: u64,
    sharedram: u64,
    bufferram: u64,
    totalswap: u64,
    freeswap: u64,
    procs: u16,
    pad: u16,
    totalhigh: u64,
    freehigh: u64,
    mem_unit: u32,
    _f: [20 - 2 * @sizeOf(u64) - @sizeOf(u32)]u8,
} else void;

pub fn getRamDisplay(buf: *[64]u8) []const u8 {
    if (comptime is_wasm) {
        const pages = @wasmMemorySize(0);
        const total_mb = (pages * 64 * 1024) / (1024 * 1024);
        return std.fmt.bufPrint(buf, "{d} MB (WASM)", .{total_mb}) catch "Error RAM";
    } else {
        var info: sysinfo_t = undefined;
        if (std.os.linux.syscall1(.sysinfo, @intFromPtr(&info)) == 0) {
            const unit: f64 = @floatFromInt(if (info.mem_unit == 0) 1 else info.mem_unit);
            const total_f: f64 = @floatFromInt(info.totalram);
            const free_f: f64 = @floatFromInt(info.freeram);
            const total_gb = (total_f * unit) / 1024 / 1024 / 1024;
            const used_gb = ((total_f - free_f) * unit) / 1024 / 1024 / 1024;
            return std.fmt.bufPrint(buf, "{d:.2}GB / {d:.2}GB", .{ used_gb, total_gb }) catch "Error";
        }
        return "Unknown";
    }
}

