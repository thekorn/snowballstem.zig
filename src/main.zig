const std = @import("std");

const c = @cImport({
    @cInclude("libstemmer.h");
});

pub fn list_stemmer(alloc: std.mem.Allocator) ![][]const u8 {
    var result = std.ArrayList([]const u8).init(alloc);
    const s = c.sb_stemmer_list();
    var p = s; // pointer to the first pointer
    while (p.* != null) {
        const v: []const u8 = std.mem.span(p.*);
        try result.append(v);
        p += 1;
    }
    return try result.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

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
    try std.testing.expectEqualStrings("arabic", stemmer[0]);
}
