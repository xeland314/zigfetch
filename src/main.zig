// src/main.zig
const std = @import("std");
const builtin = @import("builtin");

const os_info = @import("info/os.zig");
const ram_info = @import("info/ram.zig");
const browser_info = @import("info/browser.zig");
const logo = @import("render/logo.zig");

const logo_pixels = @embedFile("logo.raw");
const size = 16;

pub export fn main() void {
    const is_wasm = builtin.target.cpu.arch == .wasm32;
    const stdout = std.io.getStdOut().writer();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const os_name = if (is_wasm)
        browser_info.getName(allocator)
    else
        os_info.getLinuxOSName(allocator) catch "Linux";

    var ram_buf: [64]u8 = undefined;
    const ram_display = ram_info.getRamDisplay(&ram_buf);

    // --- RENDER ---
    var y: usize = 0;
    while (y < size) : (y += 1) {
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
        _ = stdout.write("   ") catch {};
        switch (y) {
            1 => stdout.print("\x1b[1;36m󰭹 user\x1b[0m@\x1b[1;36mportfolio\x1b[0m", .{}) catch {},
            2 => _ = stdout.write("------------") catch {},
            3 => stdout.print("\x1b[1;32m󰋜 OS: \x1b[0m{s}", .{os_name}) catch {},
            4 => stdout.print("\x1b[1;32m󰍛 RAM:\x1b[0m {s}", .{ram_display}) catch {},
            13 => logo.printColorPalette(stdout, false),
            14 => logo.printColorPalette(stdout, true),
            else => {},
        }
        _ = stdout.write("\n") catch {};
    }
}

