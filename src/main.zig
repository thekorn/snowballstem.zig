const std = @import("std");

const c = @cImport({
    @cInclude("libstemmer.h");
});

pub fn list_stemmer(alloc: std.mem.Allocator) ![][*c]const u8 {
    var result = std.ArrayList([*c]const u8).init(alloc);
    const s = c.sb_stemmer_list();
    var p = s; // pointer to the first pointer
    while (p.* != null) {
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

test "test list stemmer" {
    const alloc = std.testing.allocator;

    const stemmer = try list_stemmer(alloc);
    defer alloc.free(stemmer);

    try std.testing.expectEqual(30, stemmer.len);
}
