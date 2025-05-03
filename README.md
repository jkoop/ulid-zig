# Ulid package for Zig

This is a simple package for Zig projects that implements [ULID][ulid-spec] as an enum with convenience methods. Includes methods for `std.json` to en-/decode as a string, e.g. `"01JT9B27HTN19SEWVMWXRDRVC4"`.

- [API docs][api-docs]

## Usage

```zig
const Ulid = @import("ulid").Ulid;

// generate a new ulid // we default to non-monotonic mode
var ulid = Ulid.generate(.{}) catch unreachable;

// for monotonic mode, guaranteeing ulid to be "higher" than all previous. See api doc
var ulid = try Ulid.generate(.{ .monotonic_mode = true });

// parse a ulid from a string
var ulid = try Ulid.from_string("01JT9B27HTN19SEWVMWXRDRVC4");

// encode a ulid to a string
var buffer: [26]u8 = @splat(0);
ulid.to_string(&buffer); // overwrites the bytes of the buffer with the string and returns the string

// compare two ulids
if (ulid1 == ulid2) {
	// this 👆 is allowed; they're enums after all
}
```

## Installation

The normal procedure:

```sh
zig fetch --save https://github.com/jkoop/ulid-zig/archive/COMMIT.zip
```

```zig
// build.zig before b.installArtifact(exe);

const ulid = b.dependency("ulid", .{
    .target = target,
    .optimize = optimize,
}).module("ulid");

exe.root_module.addImport("ulid", ulid);
```

[api-docs]: https://joekoop.com/ulid-zig
[ulid-spec]: https://github.com/ulid/spec
