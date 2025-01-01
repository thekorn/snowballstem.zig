# zig wrapper for the snowball stemmer

**NOTE**: this is a work in progress, and not yet ready for use.

## Requirements

- zig >= 0.14

## how to use?

Add this package to your zig project:

```bash
$ zig fetch --save=snowballstem git+https://github.com/thekorn/snowballstem.zig.git#main
```

Add dependency and import to the `build.zig` file:

```zig
...
const minijinja = b.dependency("snowballstem", .{
    .target = target,
    .optimize = optimize,
});
...
exe.root_module.addImport("snowballstem", minijinja.module("snowballstem"));
```

And then, just use it in the code:

```zig
const std = @import("std");

const Stemmer = @import("snowballstem");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const alloc = gpa.allocator();

    const stemmer = try Stemmer.list(alloc);
    defer alloc.free(stemmer);

    std.debug.print(">>> {s}\n", .{stemmer});
}
```

## TODOS

- [ ] the build is not correct, first build sometimes fails
- [ ] implement the stemmer
- [ ] make wasm buildable
- [ ] how to handle german umlauts?
- [ ] write test for german stemmer to check against the [upstream test suite](https://github.com/snowballstem/snowball-data/blob/master/german/voc.txt)

## reference

- [snowball stemmer](https://github.com/snowballstem/snowball)