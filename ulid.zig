const std = @import("std");

pub const Ulid = enum(u128) {
    unassigned = 0,
    _,

    pub fn generate() @This() {
        const time_part: u48 = @intCast(std.time.milliTimestamp());
        const rand_part = std.crypto.random.int(u80);

        return @enumFromInt((@as(u128, @intCast(time_part)) << 80) | rand_part);
    }

    pub fn to_string(self: @This(), buffer: *[26]u8) *[26]u8 {
        const as_int = @intFromEnum(self);

        for (0..26) |index| {
            const codel: u5 = @intCast((as_int >> @intCast(index * 5)) & 0x1F);
            const char: u8 = ([32]u8{ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z' })[codel];
            buffer[25 - index] = char;
        }

        return buffer;
    }

    pub fn from_string(string: []const u8) error{ InvalidChar, InvalidLength }!@This() {
        if (string.len != 26) return error.InvalidLength;
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
                else => return error.InvalidChar,
            };
            as_int |= @as(u128, @intCast(codel)) << @intCast((25 - index) * 5);
        }

        return @enumFromInt(as_int);
    }
};

test "generate" {
    try std.testing.expect(Ulid.generate() != .unassigned);
}

test "re-encode" {
    const messy_ulid = "o1jt92gocm04D52GOzCl0IYdEG";
    const nice_ulid = "01JT92G0CM04D52G0ZC101YDEG";

    const ulid = try Ulid.from_string(messy_ulid);
    var buffer: [26]u8 = @splat(0);
    try std.testing.expect(std.mem.eql(u8, nice_ulid, ulid.to_string(&buffer)));
    try std.testing.expect(std.mem.eql(u8, nice_ulid, &buffer));
}

test "try decode bad" {
    try std.testing.expect(Ulid.from_string("123") == error.InvalidLength);
    try std.testing.expect(Ulid.from_string("##########################") == error.InvalidChar);
}
