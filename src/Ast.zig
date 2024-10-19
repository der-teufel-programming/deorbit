const std = @import("std");
const Tokenizer = @import("Tokenizer.zig");
const Token = Tokenizer.Token;

const Ast = @This();

code: [:0]const u8,
nodes: []const Node,

pub fn init(
    allocator: std.mem.Allocator,
    code: [:0]const u8,
) !Ast {
    var parser: Parser = .{
        .gpa = allocator,
        .code = code,
        .tokenizer = .{},
    };
    errdefer parser.nodes.clearAndFree(allocator);
}

pub const Node = struct {
    tag: Tag,
    loc: Token.Loc,

    pub const Tag = enum {
        root,
        integer_literal,
        float_literal,
        register,
        mnemonic_1,
        mnemonic_2,
        macro,
        builtin,
        label,
        identifier,
    };
};

const Parser = struct {
    gpa: std.mem.Allocator,
    code: [:0]const u8,
    tokenizer: Tokenizer,
    stop_on_first_error: bool,
    // diagnostic: ?*Diagnostic,
    nodes: std.ArrayListUnmanaged(Node) = .{},
    node: *Node = undefined,
    token: Token = undefined,

    pub fn parse(self: *Parser) !Ast {
        try self.nodes.ensureUnusedCapacity(self.gpa, 1);
        self.node = self.nodes.addOneAssumeCapacity();
        self.node.tag = .root;
        self.node.loc = .{ .start = 0, .end = 0 };
    }
};
