const std = @import("std");
const cli = @import("cli.zig");
const help = @import("help.zig");
const query = @import("query.zig");
const version = @import("version.zig");
const update = @import("update.zig");

pub fn main(init: std.process.Init) !u8 {
    const arena = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(arena);

    const parsed = cli.parse(argv) catch {
        try help.printHelp(std.Io.File.stderr(), init.io);
        return 1;
    };

    const ctx: cli.Context = .{
        .alloc = init.gpa,
        .io = init.io,
        .parsed = parsed,
        .environ_map = init.environ_map,
    };

    return switch (parsed.action) {
        .help => help.run(&ctx),
        .update => update.run(&ctx),
        .version => version.run(&ctx),
        .query => query.run(&ctx),
    };
}

test {
    _ = @import("cli.zig");
}
