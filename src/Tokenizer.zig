const Tokenizer = @This();

idx: usize = 0,

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Tag = enum {
        invalid,
        eof,
        comment,
        builtin,
        identifier,
        integer,
        float,
        label,
        comma,
    };

    pub const Loc = struct {
        start: usize,
        end: usize,

        pub fn code(l: Loc, src: []const u8) []const u8 {
            return src[l.start..l.end];
        }

        pub const SrcLoc = struct {
            start: SrcPos,
            end: SrcPos,

            pub const SrcPos = struct {
                line: usize,
                col: usize,
            };
        };

        pub fn srcLoc(self: Loc, src: []const u8) SrcLoc {
            var loc: SrcLoc = .{
                .start = .{
                    .line = 1,
                    .col = 1,
                },
                .end = undefined,
            };

            for (src[0..self.start]) |c| {
                if (c == '\n') {
                    loc.start.line += 1;
                    loc.start.col = 1;
                } else {
                    loc.start.col += 1;
                }
            }

            loc.end = loc.start;
            for (src[self.start..self.end]) |c| {
                if (c == '\n') {
                    loc.end.line += 1;
                    loc.end.col = 1;
                } else {
                    loc.end.col += 1;
                }
            }

            return loc;
        }
    };
};

const State = enum {
    start,
    comment,
    builtin_start,
    builtin,
    number,
    number_hex,
    number_oct,
    number_bin,
    number_qua,
    number_dec,
    number_sex,
    number_flt,
    identifier,
};

pub fn next(t: *Tokenizer, src: [:0]const u8) Token {
    var state: State = .start;
    var result: Token = .{
        .tag = .invalid,
        .loc = .{
            .start = t.idx,
            .end = undefined,
        },
    };
    while (t.idx < src.len) : (t.idx += 1) {
        const c = src[t.idx];
        switch (state) {
            .start => {
                switch (c) {
                    0 => {
                        result.tag = .eof;
                        result.loc = .{
                            .start = src.len -| 1,
                            .end = src.len,
                        };
                        break;
                    },
                    ';' => state = .comment,
                    // skip whitespace
                    ' ', '\t', '\n' => result.loc.start += 1,
                    '@' => state = .builtin_start,
                    '0' => state = .number,
                    '1'...'9' => state = .number_dec,
                    'a'...'z', 'A'...'Z' => state = .identifier,
                    ',' => {
                        t.idx += 1;
                        result.tag = .comma;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => std.debug.panic("TODO: .start: {c}", .{c}),
                }
            },
            .identifier => {
                switch (c) {
                    'a'...'z', 'A'...'Z', '_' => continue,
                    ':' => {
                        result.tag = .label;
                        result.loc.end = t.idx;
                        t.idx += 1;
                        break;
                    },
                    ',', ' ', '\n', '\t' => {
                        result.tag = .identifier;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number => {
                switch (c) {
                    '0'...'9' => state = .number_dec,
                    '.' => state = .number_flt,
                    'x' => state = .number_hex,
                    'o' => state = .number_oct,
                    'b' => state = .number_bin,
                    'q' => state = .number_qua,
                    'd' => state = .number_dec,
                    's' => state = .number_sex,
                    ',', '\n', ' ', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_dec => {
                switch (c) {
                    '0'...'9' => continue,
                    '.' => state = .number_flt,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_hex => {
                switch (c) {
                    '0'...'9', 'a'...'f', 'A'...'F' => continue,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_bin => {
                switch (c) {
                    '0', '1' => continue,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_qua => {
                switch (c) {
                    '0'...'3' => continue,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_oct => {
                switch (c) {
                    '0'...'7' => continue,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_sex => {
                switch (c) {
                    '0'...'5' => continue,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .integer;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .number_flt => {
                switch (c) {
                    '0'...'9' => continue,
                    ',', '\n', ' ', '\t', 0 => {
                        result.tag = .float;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .comment => {
                switch (c) {
                    0, '\n' => {
                        result.tag = .comment;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => continue,
                }
            },
            .builtin_start => {
                switch (c) {
                    'a'...'z' => state = .builtin,
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
            .builtin => {
                switch (c) {
                    'a'...'z', '0'...'9' => continue,
                    ' ', '\n', '\t', 0 => {
                        result.tag = .builtin;
                        result.loc.end = t.idx;
                        break;
                    },
                    else => {
                        t.idx += 1;
                        result.tag = .invalid;
                        result.loc.end = t.idx;
                        break;
                    },
                }
            },
        }
    } else {
        switch (state) {
            .start => result.tag = .eof,
            .comment => result.tag = .comment,
            .builtin => result.tag = .builtin,
            .number_flt => result.tag = .float,
            .number,
            .number_bin,
            .number_dec,
            .number_hex,
            .number_oct,
            .number_qua,
            .number_sex,
            => result.tag = .integer,
            else => result.tag = .invalid,
        }
        result.loc.end = t.idx;
    }

    return result;
}

const std = @import("std");
const log = std.log.scoped(.tokenizer);

fn testCase(case: [:0]const u8, expected_tags: []const Token.Tag) !void {
    var t: Tokenizer = .{};

    for (expected_tags, 0..) |tag, idx| {
        const tok = t.next(case);
        errdefer std.debug.print(
            "failed at index: {}\nbad token: {s} '{s}'\n",
            .{ idx, @tagName(tok.tag), tok.loc.code(case) },
        );
        try std.testing.expectEqual(tag, tok.tag);
    }
    try std.testing.expectEqual(Token.Tag.eof, t.next(case).tag);
}

fn testCase2(case: [:0]const u8, expected_tags: []const Token.Tag, expected_sources: []const []const u8) !void {
    var t: Tokenizer = .{};

    for (expected_tags, expected_sources, 0..) |tag, src, idx| {
        const tok = t.next(case);
        errdefer std.debug.print(
            "failed at index: {}\nbad token: {s} '{s}'\n",
            .{ idx, @tagName(tok.tag), tok.loc.code(case) },
        );
        try std.testing.expectEqual(tag, tok.tag);
        try std.testing.expectEqualStrings(src, tok.loc.code(case));
    }
    try std.testing.expectEqual(Token.Tag.eof, t.next(case).tag);
}

test "simple comments only" {
    const case =
        \\;this is a comment
        \\
        \\
        \\      ;this is an indented comment
    ;

    try testCase(case, &.{ .comment, .comment });
}

test "dummy builtins" {
    const case =
        \\; this is a builtin
        \\@asciiz
        \\; this looks like a builtin
        \\@notabuiltin123
    ;

    try testCase(case, &.{
        .comment,
        .builtin,
        .comment,
        .builtin,
    });
}

test "numbers" {
    const case =
        \\0x11
        \\08
        \\0o7
        \\0b110
        \\0s555
        \\0o8
        \\12.34
    ;
    try testCase(case, &.{
        .integer,
        .integer,
        .integer,
        .integer,
        .integer,
        .invalid,
        .float,
    });
}

test "idents and labels" {
    const case =
        \\this_is_a_name
        \\this_is_a_LABEL:
    ;
    try testCase2(
        case,
        &.{ .identifier, .label },
        &.{ "this_is_a_name", "this_is_a_LABEL" },
    );
}

test "take all of above" {
    const case =
        \\this_is_a_long_string_of_ones:
        \\  @u8 1, 0xFF
    ;

    try testCase2(
        case,
        &.{
            .label,
            .builtin,
            .integer,
            .comma,
            .integer,
        },
        &.{
            "this_is_a_long_string_of_ones",
            "@u8",
            "1",
            ",",
            "0xFF",
        },
    );
}
