const std = @import("std");
const cli = @import("cli.zig");
const data = @import("data.zig");
const paths = @import("paths.zig");
const ddragon = @import("ddragon.zig");

pub fn updateJson(ctx: *const cli.Context) !data.ParsedJson {
    const io = ctx.io;
    const alloc = ctx.alloc;
    const dir = ctx.dir;

    var client: std.http.Client = .{ .allocator = alloc, .io = io };
    defer client.deinit();

    const version = try ddragon.fetchLatestVersion(&client, alloc);
    defer alloc.free(version);

    const url = try ddragon.getChampionUrl(alloc, version);
    defer alloc.free(url);
    const bytes = try ddragon.fetchAlloc(&client, url, alloc);
    defer alloc.free(bytes);

    const parsed = try data.parseFromBytes(bytes, alloc);
    errdefer parsed.deinit();
    try data.saveToFile(parsed, dir, paths.championPath, io);
    return parsed;
}

pub fn run(ctx: *const cli.Context) !u8 {
    const parsed = try updateJson(ctx);
    defer parsed.deinit();

    var buf: [256]u8 = undefined;
    var bw: std.Io.File.Writer = .init(.stdout(), ctx.io, &buf);
    try bw.interface.print("updated to v{s}\n", .{parsed.value.version});
    try bw.interface.flush();
    return 0;
}
