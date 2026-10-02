const std = @import("std");
const cli = @import("cli.zig");

pub const version = "0.0.0";

pub fn run(ctx: *const cli.Context) !u8 {
    var buf: [64]u8 = undefined;
    var fw: std.Io.File.Writer = .init(.stdout(), ctx.io, &buf);
    const out = &fw.interface;

    try out.print("qwer v{s}\n", .{version});
    try out.flush();
    return 0;
}
