const std = @import("std");

pub const base_url = "https://ddragon.leagueoflegends.com";
pub const locale = "en_US";
pub const versions_url = base_url ++ "/api/versions.json";

pub fn getChampionUrl(alloc: std.mem.Allocator, version: []const u8) ![]u8 {
    return std.fmt.allocPrint(alloc, "{s}/cdn/{s}/data/{s}/championFull.json", .{
        base_url, version, locale,
    });
}

pub fn fetchAlloc(client: *std.http.Client, url: []const u8, alloc: std.mem.Allocator) ![]u8 {
    var out: std.Io.Writer.Allocating = .init(alloc);
    errdefer out.deinit();
    const res = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &out.writer,
    });
    if (res.status != .ok) return error.HttpStatus;
    return out.toOwnedSlice();
}

pub fn fetchLatestVersion(client: *std.http.Client, alloc: std.mem.Allocator) ![]u8 {
    const body = try fetchAlloc(client, versions_url, alloc);
    defer alloc.free(body);

    const parsed = try std.json.parseFromSlice([]const []const u8, alloc, body, .{});
    defer parsed.deinit();
    if (parsed.value.len == 0) return error.NoVersions;
    return alloc.dupe(u8, parsed.value[0]);
}
