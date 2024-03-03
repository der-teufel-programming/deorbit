const std = @import("std");
const deorbit = @import("deorbit");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    const options = try parseOptions(allocator, args);
    _ = options;

    const fname = args.next() orelse helpFatal();
    const src = try std.fs.cwd().readFileAllocOptions(
        allocator,
        fname,
        std.math.maxInt(usize),
        null,
        @alignOf(u8),
        0,
    );
    defer allocator.free(src);

    var t: deorbit.Tokenizer = .{};

    while (true) {
        const tok = t.next(src);
        std.debug.print("{any}\n", .{tok});
        if (tok.tag == .eof) break;
    }
}

fn parseOptions(allocator: std.mem.Allocator, args: std.process.ArgIterator) !void {
    _ = allocator;
    _ = args;
}

fn helpFatal() noreturn {
    std.debug.print(
        \\Usage:
        \\deorbit PATH [OPTIONS]
    , .{});
    std.process.exit(1);
}
