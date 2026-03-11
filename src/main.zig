const std = @import("std");
const builtin = @import("builtin");

const logo_pixels = @embedFile("logo.raw");
const size = 16;

// Estructura para sysinfo (solo Linux) - NO SE NECESITA EN WASM WASI
const sysinfo_t = extern struct {
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
};

pub export fn main() void {
    const is_wasm = builtin.target.cpu.arch == .wasm32;
    const stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // --- DETECCIÓN DE INFO ---
    const os_name = if (is_wasm) "Web Browser (WASM)" else getLinuxOSName(allocator) catch "Linux";

    var ram_str: [64]u8 = undefined;
    
    // --- RENDER ---
    var y: usize = 0;
    while (y < size) : (y += 1) {
        // 1. Dibujar línea del Logo
        var x: usize = 0;
        while (x < size) : (x += 1) {
            const i = (y * size + x) * 4;
            const r = logo_pixels[i];
            const g = logo_pixels[i + 1];
            const b = logo_pixels[i + 2];
            const a = logo_pixels[i + 3];

            if (a < 128) {
                _ = stdout.write("  ") catch {};
            } else {
                stdout.print("\x1b[48;2;{d};{d};{d}m  \x1b[0m", .{ r, g, b }) catch {};
            }
        }

        // 2. Dibujar Info a la derecha (Margen de 3 espacios)
        _ = stdout.write("   ") catch {};
        switch (y) {
            1 => stdout.print("\x1b[1;36m󰭹 user\x1b[0m@\x1b[1;36mportfolio\x1b[0m", .{}) catch {},
            2 => _ = stdout.write("------------") catch {},
            3 => stdout.print("\x1b[1;32m󰋜 OS: \x1b[0m{s}", .{os_name}) catch {},
            4 => stdout.print("\x1b[1;32m󰍛 RAM:\x1b[0m {s}", .{ram_display}) catch {},
            // Paleta de colores movida aquí para que no rompa el layout
            13 => printColorPalette(stdout, false),
            14 => printColorPalette(stdout, true),
            else => {},
        }
        _ = stdout.write("\n") catch {};
    }
}

fn printColorPalette(writer: anytype, bright: bool) void {
    const base = if (bright) @as(u8, 100) else @as(u8, 40);
    var i: u8 = 0;
    while (i < 8) : (i += 1) {
        writer.print("\x1b[{d}m  ", .{base + i}) catch {};
    }
    _ = writer.write("\x1b[0m") catch {};
}

fn getLinuxOSName(allocator: std.mem.Allocator) ![]const u8 {
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

