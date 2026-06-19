// src/main.zig
const std = @import("std");
const builtin = @import("builtin");

const os_info = @import("info/os.zig");
const ram_info = @import("info/ram.zig");
const browser_info = @import("info/browser.zig");
const logo = @import("render/logo.zig");

const logo_pixels = @embedFile("logo.raw");
const size = 16;

const DisplayMode = enum {
    horizontal,
    vertical,
};

pub export fn main() void {
    const is_wasm = builtin.target.cpu.arch == .wasm32;
    var stdout_buf: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // --- PARSEO DE ARGUMENTOS ---
    var mode = DisplayMode.horizontal; // Comportamiento original por defecto

    if (!is_wasm) {
        var args = std.process.args();
        // El primer argumento es siempre el nombre del ejecutable
        _ = args.skip();
        while (args.next()) |arg| {
            if (std.mem.eql(u8, arg, "--vertical") or std.mem.eql(u8, arg, "-v")) {
                mode = .vertical;
            } else if (std.mem.eql(u8, arg, "--horizontal") or std.mem.eql(u8, arg, "-h")) {
                mode = .horizontal;
            }
        }
    }

    // --- RECOLECCIÓN DE INFORMACIÓN (Se mantiene idéntica) ---
    const os_name = if (is_wasm) browser_info.getName(allocator) else os_info.getLinuxOSName(allocator) catch "Linux";
    var ram_buf: [64]u8 = undefined;
    const ram_display = ram_info.getRamDisplay(&ram_buf);
    const lang = if (is_wasm) browser_info.getSystemLanguage(allocator) else os_info.getLanguage(allocator);
    const resolution = if (is_wasm) browser_info.getScreenResolution(allocator) else os_info.getResolution(allocator);
    const cpu_cores = if (is_wasm) browser_info.getCpuCoreCount() else os_info.getCpuCores();
    const domain = if (is_wasm) browser_info.getDomainName(allocator) else os_info.getDomain(allocator);
    const gpu = if (is_wasm) browser_info.getGpuRenderer(allocator) else os_info.getGpu(allocator);

    switch (mode) {
        .horizontal => {
            // El comportamiento clásico que ya tenías (Neofetch style)
            var y: usize = 0;
            while (y < size) : (y += 1) {
                renderLogoRow(y, stdout);
                _ = stdout.write("   ") catch {};
                renderInfoRow(y, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
                _ = stdout.write("\n") catch {};
            }
        },
        .vertical => {
            // El nuevo comportamiento apilado hacia abajo
            var y: usize = 0;
            while (y < size) : (y += 1) {
                renderLogoRow(y, stdout);
                _ = stdout.write("\n") catch {};
            }
            _ = stdout.write("\n") catch {}; // Espaciador

            // Imprimimos de corrido pasándole los índices del switch de forma secuencial
            renderInfoRow(1, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(2, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(3, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(4, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(5, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(6, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            if (cpu_cores > 0) {
                renderInfoRow(7, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
                _ = stdout.write("\n") catch {};
            }
            renderInfoRow(8, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(9, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};

            _ = stdout.write("\n") catch {};
            renderInfoRow(13, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
            renderInfoRow(14, os_name, ram_display, lang, resolution, cpu_cores, domain, gpu, stdout);
            _ = stdout.write("\n") catch {};
        },
    }

    _ = stdout.flush() catch {};
}

// Helper para encapsular el renderizado de una fila del logo
fn renderLogoRow(y: usize, stdout: anytype) void {
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
}

// Helper que encapsula tu antiguo bloque switch para reutilizarlo en ambos flujos
fn renderInfoRow(
    y: usize,
    os_name: []const u8,
    ram_display: []const u8,
    lang: []const u8,
    resolution: []const u8,
    cpu_cores: usize,
    domain: []const u8,
    gpu: []const u8,
    stdout: anytype,
) void {
    switch (y) {
        1 => stdout.print("\x1b[1;36m󰭹 xeland314\x1b[0m@\x1b[1;36mportfolio\x1b[0m", .{}) catch {},
        2 => _ = stdout.write("------------") catch {},
        3 => stdout.print("\x1b[1;32m󰋜 OS: \x1b[0m{s}", .{os_name}) catch {},
        4 => stdout.print("\x1b[1;32m󰍛 RAM:\x1b[0m {s}", .{ram_display}) catch {},
        5 => stdout.print("\x1b[1;32m󰗊 Lang:\x1b[0m {s}", .{lang}) catch {},
        6 => stdout.print("\x1b[1;32m󰍹 Res: \x1b[0m{s}", .{resolution}) catch {},
        7 => if (cpu_cores > 0) stdout.print("\x1b[1;32m󰻠 CPU: \x1b[0m{d} cores", .{cpu_cores}) catch {},
        8 => stdout.print("\x1b[1;32m󰖟 Host:\x1b[0m {s}", .{domain}) catch {},
        9 => stdout.print("\x1b[1;32m󰢮 GPU: \x1b[0m{s}", .{gpu}) catch {},
        13 => logo.printColorPalette(stdout, false),
        14 => logo.printColorPalette(stdout, true),
        else => {},
    }
}

