const std = @import("std");

// @todo confirm that these variables are shared across all `@import`s of this lib.
var mutex: std.Thread.Mutex = .{};
var last_gen_millisecond: u48 = 0;
var last_gen_random: u80 = 0;

pub const Ulid = enum(u128) {
    unassigned = 0,
    _,

    /// A mutex is consulted during generation, and if this call for generation occurs
    /// during the same millisecond as another, the returned ulid will have a random
    /// part of one more than the previous ulid (as if the whole thing is one huge
    /// incrementing number).
    /// https://github.com/ulid/spec?tab=readme-ov-file#monotonicity
    pub fn generateMonotonic() error{Overflow}!@This() {
        const time_part: u48 = @intCast(std.time.milliTimestamp());

        {
            mutex.lock();
            defer mutex.unlock();

            if (time_part == last_gen_millisecond) {
                if (last_gen_random == 0xFFFFFFFFFFFFFFFFFFFF) {
                    return error.Overflow;
                }

                last_gen_random += 1;
            } else {
                last_gen_millisecond = time_part;
                last_gen_random = std.crypto.random.int(u80);
            }
        }

        return @enumFromInt((@as(u128, @intCast(last_gen_millisecond)) << 80) | last_gen_random);
    }

    /// The mutex is not consulted (which may cause races with other threads using
    /// .generateMonotonic()). The random part is random.
    pub fn generateRandom() @This() {
        last_gen_millisecond = @intCast(std.time.milliTimestamp());
        last_gen_random = std.crypto.random.int(u80);
        return @enumFromInt((@as(u128, @intCast(last_gen_millisecond)) << 80) | last_gen_random);
    }

    pub fn toString(self: @This(), buffer: *[26]u8) *[26]u8 {
        const as_int = @intFromEnum(self);

        for (0..26) |index| {
            const codel: u5 = @intCast((as_int >> @intCast(index * 5)) & 0x1F);
            const char: u8 = ([32]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z' })[codel];
            buffer[25 - index] = char;
        }

        return buffer;
    }

    pub fn fromString(string: []const u8) error{ InvalidCharacter, LengthMismatch }!@This() {
        if (string.len != 26) return error.LengthMismatch;
        var as_int: u128 = 0;

        for (0..26) |index| {
            const char: u8 = string[index];
            const codel: u5 = switch (char) {
                '0', 'O', 'o' => 0,
                '1', 'I', 'i', 'L', 'l' => 1,
                '2' => 2,
                '3' => 3,
                '4' => 4,
                '5' => 5,
                '6' => 6,
                '7' => 7,
                '8' => 8,
                '9' => 9,
                'A', 'a' => 10,
                'B', 'b' => 11,
                'C', 'c' => 12,
                'D', 'd' => 13,
                'E', 'e' => 14,
                'F', 'f' => 15,
                'G', 'g' => 16,
                'H', 'h' => 17,
                'J', 'j' => 18,
                'K', 'k' => 19,
                'M', 'm' => 20,
                'N', 'n' => 21,
                'P', 'p' => 22,
                'Q', 'q' => 23,
                'R', 'r' => 24,
                'S', 's' => 25,
                'T', 't' => 26,
                'V', 'v' => 27,
                'W', 'w' => 28,
                'X', 'x' => 29,
                'Y', 'y' => 30,
                'Z', 'z' => 31,
                else => return error.InvalidCharacter,
            };

            // https://github.com/ulid/spec?tab=readme-ov-file#overflow-errors-when-parsing-base32-strings
            if (index == 0 and (codel & 0b11000) > 0) {
                return error.InvalidCharacter;
            }

            as_int |= @as(u128, @intCast(codel)) << @intCast((25 - index) * 5);
        }

        return @enumFromInt(as_int);
    }

    /// Used by `std.json`; parses from a string like `from_string()`
    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) std.json.ParseError(@TypeOf(source.*))!@This() {
        const string: []u8 = try std.json.innerParse([]u8, allocator, source, options);
        defer allocator.free(string);
        const ulid: @This() = try fromString(string);
        return ulid;
    }

    /// Used by `std.json`; encodes to a string like `to_string()`
    pub fn jsonStringify(self: @This(), stream: anytype) !void {
        var buffer: [26]u8 = @splat(0);
        _ = self.toString(&buffer);
        try stream.write(buffer);
    }
};

test "generate" {
    try std.testing.expect(try Ulid.generateMonotonic() != .unassigned);
    try std.testing.expect(Ulid.generateRandom() != .unassigned);
}

test "re-encode" {
    const messy_ulid = "o1jt92gocm04D52GOzCl0IYdEG";
    const nice_ulid = "01JT92G0CM04D52G0ZC101YDEG";

    const ulid = try Ulid.fromString(messy_ulid);
    var buffer: [26]u8 = @splat(0);
    try std.testing.expect(std.mem.eql(u8, nice_ulid, ulid.toString(&buffer)));
    try std.testing.expect(std.mem.eql(u8, nice_ulid, &buffer));
}

test "try decode bad" {
    try std.testing.expect(Ulid.fromString("123") == error.LengthMismatch);
    try std.testing.expect(Ulid.fromString("##########################") == error.InvalidCharacter);
}

test "json" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ulid: Ulid = @enumFromInt(2111036925982184970599634536618735056);
    const json = try std.json.Stringify.valueAlloc(allocator, ulid, .{});
    try std.testing.expect(std.mem.eql(u8, json, "\"01JT92G0CM04D52G0ZC101YDEG\""));

    const ulid2 = try std.json.parseFromSliceLeaky(Ulid, allocator, json, .{});
    try std.testing.expect(ulid == ulid2);
}
