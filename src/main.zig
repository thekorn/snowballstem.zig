const std = @import("std");

pub const Stemmer = @import("Stemmer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    const stemmer = try Stemmer.list(alloc);
    defer alloc.free(stemmer);

    std.debug.print(">>> {s}\n", .{stemmer});

    var s = try Stemmer.init("english", "UTF_8");
    defer s.deinit();

    std.debug.print(">>> {any}\n", .{s});

    const result = s.stem("absurdities");

    std.debug.print("RESULT:: {s}\n", .{result});
}

test "test list stemmer" {
    const alloc = std.testing.allocator;

    const stemmer = try Stemmer.list(alloc);
    defer alloc.free(stemmer);

    try std.testing.expectEqual(30, stemmer.len);
    try std.testing.expectEqualStrings("arabic", stemmer[0]);
}

test "test init english stemmer" {
    var s = try Stemmer.init("english", "UTF_8");
    defer s.deinit();

    var t = try Stemmer.init("en", "UTF_8");
    defer t.deinit();
}

test "test init unknown stemmer" {
    try std.testing.expectError(error.UnknownLanguageOrCharenc, Stemmer.init("e", "UTF_8"));
}

test "test english stemmer" {
    var s = try Stemmer.init("english", "UTF_8");
    defer s.deinit();

    try std.testing.expectEqualStrings("absurd", s.stem("absurdities"));
}

test "test german stemmer" {
    var s = try Stemmer.init("german", "UTF_8");
    defer s.deinit();

    try std.testing.expectEqualStrings("abgeordnetenversamml", s.stem("abgeordnetenversammlung"));

    //try std.testing.expectEqualStrings("abenddämmerung", s.stem("abenddammer"));
}
