const std = @import("std");
const builtin = @import("builtin");

pub fn cacheDir(alloc: std.mem.Allocator, env: *std.process.Environ.Map) ![]const u8 {
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
