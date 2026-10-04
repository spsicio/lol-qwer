const std = @import("std");
const query = @import("query.zig");
const QueryError = query.QueryError;

const Stats = struct {
    movespeed: u16,
    attackrange: u16,
};

const Spell = struct {
    cooldownBurn: []const u8,
    rangeBurn: []const u8,
};

const Champion = struct {
    stats: Stats,
    spells: []const Spell,
};

const ChampionFull = struct {
    data: std.json.ArrayHashMap(Champion),
    version: []const u8,
};
pub const ParsedJson = std.json.Parsed(ChampionFull);

const ChampionWithName = struct {
    champion: Champion,
    name: []const u8,
};

pub fn queryChampion(json: ChampionFull, name: []const u8) QueryError!ChampionWithName {
    var it = json.data.map.iterator();
    while (it.next()) |e| {
        if (std.ascii.eqlIgnoreCase(e.key_ptr.*, name)) {
            return .{
                .champion = e.value_ptr.*,
                .name = e.key_ptr.*,
            };
        }
    }
    return QueryError.ChampionNotFound;
}

pub fn parseFromFile(
    file: std.Io.File,
    io: std.Io,
    gpa: std.mem.Allocator,
) !ParsedJson {
    var buf: [4096]u8 = undefined;
    var fr = file.reader(io, &buf);
    var jr: std.json.Reader = .init(gpa, &fr.interface);
    defer jr.deinit();

    return std.json.parseFromTokenSource(ChampionFull, gpa, &jr, .{
        .ignore_unknown_fields = true,
    });
}

pub fn parseFromBytes(bytes: []const u8, gpa: std.mem.Allocator) !ParsedJson {
    return std.json.parseFromSlice(ChampionFull, gpa, bytes, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    });
}

pub fn saveToFile(
    json: ParsedJson,
    dir: std.Io.Dir,
    sub_path: []const u8,
    io: std.Io,
) !void {
    var af = try dir.createFileAtomic(io, sub_path, .{ .replace = true });
    defer af.deinit(io);
    var buf: [4096]u8 = undefined;
    var bw: std.Io.File.Writer = .init(af.file, io, &buf);
    var js: std.json.Stringify = .{ .writer = &bw.interface, .options = .{} };

    try js.write(json.value);
    try bw.interface.flush();
    try af.replace(io);
}
