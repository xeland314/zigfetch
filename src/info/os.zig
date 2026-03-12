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

pub fn getLanguage(allocator: std.mem.Allocator) []const u8 {
    // Lee la variable de entorno LANG (ej: "es_EC.UTF-8" → "es-EC")
    const lang = std.process.getEnvVarOwned(allocator, "LANG") catch return "unknown";
    // Recorta el encoding (.UTF-8)
    if (std.mem.indexOf(u8, lang, ".")) |dot| {
        return lang[0..dot];
    }
    return lang;
}

pub fn getResolution(allocator: std.mem.Allocator) []const u8 {
    // Intenta leer xrandr
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "xrandr", "--current" },
    }) catch return "unknown";

    var lines = std.mem.tokenizeAny(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        // Busca la línea con el asterisco (resolución activa)
        if (std.mem.indexOf(u8, line, "*") != null) {
            var tokens = std.mem.tokenizeAny(u8, line, " ");
            if (tokens.next()) |res| {
                return allocator.dupe(u8, res) catch "unknown";
            }
        }
    }
    return "unknown";
}

pub fn getCpuCores() u32 {
    // Lee /proc/cpuinfo y cuenta los "processor" entries
    const file = std.fs.openFileAbsolute("/proc/cpuinfo", .{}) catch return 0;
    defer file.close();
    const buf: [65536]u8 = undefined;
    const content = file.readToEndAlloc(std.heap.page_allocator, buf.len) catch return 0;
    var count: u32 = 0;
    var lines = std.mem.tokenizeAny(u8, content, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "processor")) count += 1;
    }
    return count;
}

pub fn getDomain(allocator: std.mem.Allocator) []const u8 {
    // Lee el hostname del sistema
    var buf: [64]u8 = undefined;
    const hostname = std.posix.gethostname(&buf) catch return "unknown";
    return allocator.dupe(u8, hostname) catch "unknown";
}

pub fn getGpu(allocator: std.mem.Allocator) []const u8 {
    // Intenta lglxinfo primero, luego /proc/driver como fallback
    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "glxinfo", "-B" },
    }) catch return tryProcGpu(allocator);

    var lines = std.mem.tokenizeAny(u8, result.stdout, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "OpenGL renderer string:")) {
            const val = std.mem.trim(u8, line[23..], " ");
            return allocator.dupe(u8, val) catch "unknown";
        }
    }
    return "unknown";
}

fn tryProcGpu(allocator: std.mem.Allocator) []const u8 {
    // Fallback: lee /proc/driver/nvidia/version o similar
    const file = std.fs.openFileAbsolute("/proc/driver/nvidia/version", .{}) catch return "unknown";
    defer file.close();
    const content = file.readToEndAlloc(allocator, 512) catch return "unknown";
    var lines = std.mem.tokenizeAny(u8, content, "\n");
    if (lines.next()) |line| {
        return allocator.dupe(u8, line) catch "unknown";
    }
    return "unknown";
}
