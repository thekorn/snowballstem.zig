const std = @import("std");

const c = @cImport({
    @cInclude("libstemmer.h");
});

pub fn list_stemmer(alloc: std.mem.Allocator) ![][*c]const u8 {
    var result = std.ArrayList([*c]const u8).init(alloc);
    const s = c.sb_stemmer_list();
    var p = s; // pointer to the first pointer
    while (p.* != null) {
        std.debug.print("Found string: {s}\n", .{p.*});
        try result.append(p.*);
        p += 1; // move to the next pointer
    }
    return try result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    const stemmer = try list_stemmer(alloc);
    defer alloc.free(stemmer);

    for (stemmer) |s| {
        std.debug.print(">>> {s}\n", .{s});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const global = struct {
        fn testOne(input: []const u8) anyerror!void {
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(global.testOne, .{});
}
