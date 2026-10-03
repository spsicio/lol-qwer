const std = @import("std");
const cli = @import("cli.zig");
const data = @import("data.zig");
const paths = @import("paths.zig");
const update = @import("update.zig");

pub const QueryError = error{
    ChampionNotFound,
};

pub fn run(ctx: *const cli.Context) !u8 {
    const io = ctx.io;
    const alloc = ctx.alloc;
    const dir = ctx.dir;
    const name = ctx.parsed.champion.?;

    const parsed = blk: {
        const file =
            dir.openFile(io, "championFull.json", .{}) catch |err| {
                switch (err) {
                    error.FileNotFound => break :blk try update.updateJson(ctx),
                    else => return err,
                }
            };
        defer file.close(io);
        break :blk try data.parseFromFile(file, io, alloc);
    };
    defer parsed.deinit();

    // query
    const championWithName = try data.queryChampion(parsed.value, name);
    const champion = championWithName.champion;
    const display = championWithName.name;
    const stats = champion.stats;
    const spells = champion.spells;
    const letters = [_][]const u8{ "Q", "W", "E", "R" };

    var buf: [512]u8 = undefined;
    var bw: std.Io.File.Writer = .init(.stdout(), io, &buf);
    const out = &bw.interface;

    try out.print("{s} v{s}\n", .{ display, parsed.value.version });
    var cd_width: usize = 0;
    for (letters, 0..) |letter, i| {
        const w = letter.len + "CD: ".len + spells[i].cooldownBurn.len;
        if (w > cd_width) cd_width = w;
    }
    for (letters, 0..) |letter, i| {
        const sp = spells[i];
        try out.print("{s}  CD: {s}", .{ letter, sp.cooldownBurn });
        const cur = letter.len + "CD: ".len + sp.cooldownBurn.len;
        try printSpaces(out, cd_width - cur + 2);
        try out.print("Range: {s}\n", .{sp.rangeBurn});
    }
    try out.print("Move   Speed      {d}\n", .{stats.movespeed});
    try out.print("Attack Range      {d}\n", .{stats.attackrange});

    try out.flush();
    return 0;
}

fn printSpaces(out: *std.Io.Writer, count: usize) !void {
    var n = count;
    while (n > 0) : (n -= 1) {
        try out.writeByte(' ');
    }
}
