const std = @import("std");

const c = @cImport({
    @cInclude("libstemmer.h");
});

const Self = @This();

stemmer: *c.struct_sb_stemmer,

pub fn init(language: []const u8, charenc: []const u8) !Self {
    const c_lang: [*c]const u8 = @ptrCast(language);
    const c_enc: [*c]const u8 = @ptrCast(charenc);
    const stemmer = c.sb_stemmer_new(c_lang, c_enc) orelse return error.UnknownLanguageOrCharenc;
    return .{
        .stemmer = stemmer,
    };
}

pub fn stem(self: *Self, word: []const u8) []const u8 {
    const c_word: [*c]const u8 = @ptrCast(word);
    const c_len: c_int = @intCast(word.len);
    const result = c.sb_stemmer_stem(self.stemmer, c_word, c_len);
    return std.mem.span(result);
}

pub fn deinit(self: *Self) void {
    c.sb_stemmer_delete(self.stemmer);
}

pub fn list(alloc: std.mem.Allocator) ![][]const u8 {
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
