# Ulid package for Zig

This is a simple package for Zig projects that implements [ULID][ulid-spec] as an enum with convenience methods. Includes methods for `std.json` to en-/decode as a string, e.g. `"01JT9B27HTN19SEWVMWXRDRVC4"`.

- [API docs][api-docs]

## Usage

```zig
const Ulid = @import("ulid").Ulid;

// generate a new ulid
var ulid = Ulid.generateRandom();

// for monotonic mode, guaranteeing ulid to be "higher" than all previous (see api doc)
var ulid = try Ulid.generateMonotonic();

// parse a ulid from a string
var ulid = try Ulid.fromString("01JT9B27HTN19SEWVMWXRDRVC4");

// encode a ulid to a string
var buffer: [26]u8 = @splat(0);
ulid.toString(&buffer); // overwrites the bytes of the buffer with the string and returns the string

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
// add to your build.zig, in your Module's .imports
.{
    .name = "ulid",
    .module = b.dependency("ulid", .{ .target = target }).module("ulid"),
},
```

[api-docs]: https://joekoop.com/ulid-zig
[ulid-spec]: https://github.com/ulid/spec
