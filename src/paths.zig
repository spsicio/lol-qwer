const std = @import("std");
const builtin = @import("builtin");

pub const championPath = "championFull.json";

fn getCachePath(alloc: std.mem.Allocator, env: *std.process.Environ.Map) ![]const u8 {
    if (builtin.os.tag == .windows) {
        const base = env.get("LOCALAPPDATA") orelse return error.NoCacheDir;
        return std.Io.Dir.path.join(alloc, &.{ base, "qwer" });
    }
    if (env.get("XDG_CACHE_HOME")) |xdg| {
        return std.Io.Dir.path.join(alloc, &.{ xdg, "qwer" });
    }
    const home = env.get("HOME") orelse return error.NoCacheDir;
    return std.Io.Dir.path.join(alloc, &.{ home, ".cache", "qwer" });
}

pub fn getCacheDir(
    io: std.Io,
    alloc: std.mem.Allocator,
    env: *std.process.Environ.Map,
) !std.Io.Dir {
    const path = try getCachePath(alloc, env);
    defer alloc.free(path);
    return std.Io.Dir.cwd().createDirPathOpen(io, path, .{});
}
