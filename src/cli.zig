const std = @import("std");

pub const Action = enum { help, query, update, version };

pub const Parsed = struct {
    action: Action,
    champion: ?[:0]const u8 = null,
};

pub const Context = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    parsed: Parsed,
    dir: std.Io.Dir,
};

pub const ParseError = error{
    ConflictingActions,
    MissingOperands,
    TooManyOperands,
    UnknownOption,
};

pub fn parse(argv: []const [:0]const u8) ParseError!Parsed {
    var action: ?Action = null;
    var champion: ?[:0]const u8 = null;

    const setAction = struct {
        fn func(slot: *?Action, a: Action) ParseError!void {
            if (slot.*) |old| {
                if (a != old) {
                    return error.ConflictingActions;
                }
            } else {
                slot.* = a;
            }
        }
    }.func;
    const setChampion = struct {
        fn func(slot: *?[:0]const u8, c: [:0]const u8) ParseError!void {
            if (slot.* != null) {
                return error.TooManyOperands;
            } else {
                slot.* = c;
            }
        }
    }.func;

    var i: usize = 1;
    // phase 1: options
    while (i < argv.len) : (i += 1) {
        const arg = argv[i];
        if (std.mem.eql(u8, arg, "--")) {
            i += 1;
            break;
        }
        if (arg.len < 2 or arg[0] != '-') break;
        for (arg[1..]) |ch| {
            const a: Action = switch (ch) {
                'h' => .help,
                'u' => .update,
                'v' => .version,
                else => return error.UnknownOption,
            };
            try setAction(&action, a);
        }
    }
    // phase 2: operands
    while (i < argv.len) : (i += 1) {
        try setChampion(&champion, argv[i]);
    }

    if (action == null) {
        action = .query;
        if (champion == null) {
            return error.MissingOperands;
        }
    }
    return .{ .action = action.?, .champion = champion };
}

test "ConflictingActions" {
    const same_h = [_][:0]const u8{ "qwer", "-hh" };
    const same_u = [_][:0]const u8{ "qwer", "-uu" };
    const same_v = [_][:0]const u8{ "qwer", "-vv" };
    try std.testing.expectEqual(Action.help, (try parse(&same_h)).action);
    try std.testing.expectEqual(Action.update, (try parse(&same_u)).action);
    try std.testing.expectEqual(Action.version, (try parse(&same_v)).action);

    const c1 = [_][:0]const u8{ "qwer", "-hu" };
    const c2 = [_][:0]const u8{ "qwer", "-hv" };
    const c3 = [_][:0]const u8{ "qwer", "-uv" };
    try std.testing.expectError(error.ConflictingActions, parse(&c1));
    try std.testing.expectError(error.ConflictingActions, parse(&c2));
    try std.testing.expectError(error.ConflictingActions, parse(&c3));
}

test "MissingOperands" {
    const argv1 = [_][:0]const u8{"qwer"};
    const argv2 = [_][:0]const u8{ "qwer", "--" };
    try std.testing.expectError(error.MissingOperands, parse(&argv1));
    try std.testing.expectError(error.MissingOperands, parse(&argv2));
}

test "TooManyOperands" {
    const argv = [_][:0]const u8{ "qwer", "Ahri", "Sona" };
    try std.testing.expectError(error.TooManyOperands, parse(&argv));
}

test "UnknownOptions" {
    const a = [_][:0]const u8{ "qwer", "-x" };
    try std.testing.expectError(error.UnknownOption, parse(&a));
}

test "NormalActions" {
    const h = [_][:0]const u8{ "qwer", "-h" };
    const u = [_][:0]const u8{ "qwer", "-u" };
    const v = [_][:0]const u8{ "qwer", "-v" };
    try std.testing.expectEqual(Action.help, (try parse(&h)).action);
    try std.testing.expectEqual(Action.update, (try parse(&u)).action);
    try std.testing.expectEqual(Action.version, (try parse(&v)).action);
}

test "NormalChampion" {
    const argv = [_][:0]const u8{ "qwer", "Ahri" };
    const p = try parse(&argv);
    try std.testing.expectEqual(Action.query, p.action);
    try std.testing.expectEqualStrings("Ahri", p.champion.?);
}

test "SingularChampions" {
    const argv1 = [_][:0]const u8{ "qwer", "-" };
    const argv2 = [_][:0]const u8{ "qwer", "--", "-h" };
    try std.testing.expectEqualStrings("-", (try parse(&argv1)).champion.?);
    try std.testing.expectEqualStrings("-h", (try parse(&argv2)).champion.?);
}

test "HelpGoesFirst" {
    const argv = [_][:0]const u8{ "qwer", "-h", "Ahri" };
    const p = try parse(&argv);
    try std.testing.expectEqual(Action.help, p.action);
    try std.testing.expectEqualStrings("Ahri", p.champion.?);
}
