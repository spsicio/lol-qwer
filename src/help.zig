const std = @import("std");
const cli = @import("cli.zig");

pub fn printHelp(file: std.Io.File, io: std.Io) !void {
    var buf: [512]u8 = undefined;
    var fw: std.Io.File.Writer = .init(file, io, &buf);
    const out = &fw.interface;

    try out.writeAll(
        \\usage: qwer [options]... <champion-name>
        \\
        \\  -h      Print this help
        \\  -u      Update LOL data
        \\  -v      Print version number of qwer and data
    );
    try out.flush();
}

pub fn run(ctx: *const cli.Context) !u8 {
    try printHelp(std.Io.File.stdout(), ctx.io);
    return 0;
}
