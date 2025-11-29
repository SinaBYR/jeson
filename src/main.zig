const std = @import("std");
const fs = @import("std").fs;
const ascii = @import("std").ascii;
const expect = @import("std").testing.expect;

const Reader = struct {
    size: u64,
    content: []u8,
    curr: u32,
    fn trim_space(self: *Reader) void {
        while(self.curr < self.size and ascii.isWhitespace(self.content[self.curr])) {
            self.curr += 1;
        }
    }

    fn trim_space_end(self: *Reader) void {
        var i = self.size - 1;
        while(i > 0 and ascii.isWhitespace(self.content[i])) {
            i -= 1;
            self.size -= 1;
        }
    }

    fn parse_numeric(self: *Reader) void {
        while(self.curr < self.size and ascii.isDigit(self.content[self.curr])) {
            self.curr += 1;
        }
    }

    fn parse_bool(self: *Reader) u8 {
        const false_bool = self.content[self.curr..self.curr + 5];
        const true_bool = self.content[self.curr..self.curr + 4];
        if (std.mem.eql(u8, true_bool, "true")) {
            self.curr += 4;
            return 0;
        }

        if (std.mem.eql(u8, false_bool, "false")) {
            self.curr += 5;
            return 0;
        }

        return 1;
    }

    fn parse_value(self: *Reader) u8 {
        var char = self.content[self.curr];
        if (char == '"') {
            self.curr += 1;
            char = self.content[self.curr];

            while (ascii.isAlphanumeric(self.content[self.curr])) {
                self.curr += 1;
            }

            char = self.content[self.curr];
            if (char != '"') {
                std.debug.print("Missing double quote \" at {d}\n", .{self.curr});
                return 1;
            }
            self.curr += 1;
            return 0;
        } else {
            if (char == '[') {
                // while(self.curr < file_size and (ascii.))
                return 0;
            } else {
                if (char == '{') {
                    // while(self.curr < file_size and (ascii.))
                    return 0;
                } else {
                    if (ascii.isDigit(self.content[self.curr])) {
                        self.parse_numeric();
                        return 0;
                    } else {
                        return self.parse_bool();
                    }
                }
            }
        }
    }

    fn parse_key(self: *Reader) void {
        var char = self.content[self.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, self.content[self.curr - 1]});
            return;
        }

        self.curr += 1;
        char = self.content[self.curr];

        const curr_temp = self.curr;
        while (ascii.isAlphabetic(self.content[self.curr])) {
            self.curr += 1;
        }

        if (curr_temp == self.curr) {
            std.debug.print("Field name cannot be empty\n", .{});
            return;
        }

        char = self.content[self.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
            return;
        }
        self.curr += 1;
    }

    fn parse(self: *Reader) void {
        // remove spaces from the end, reducing end spaces from self.size value
        self.trim_space_end();

        var char = self.content[self.curr];
        if (char != '{') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
            return;
        }

        if (self.curr + 1 > self.size) {
            std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
            return;
        }

        self.curr += 1;
        self.trim_space();
        char = self.content[self.curr];
        if (char == '}') {
            std.debug.print("{s}\n", .{self.content});
            return;
        }

        var repeat = true;
        while(repeat) {
            repeat = false;
            self.trim_space();
            self.parse_key();
            self.trim_space();

            char = self.content[self.curr];
            if (char != ':') {
                std.debug.print("Expected colon (:), but found \"{c}\" at {d}.\n", .{char, self.curr});
                return;
            }
            self.curr += 1;

            self.trim_space();
            const code = self.parse_value();
            if (code != 0) {
                return;
            }
            self.trim_space();

            if (self.curr + 1 > self.size) {
                char = self.content[self.curr - 1];
                std.debug.print("Expected closing curly brace at {d}.\n", .{self.curr});
                return;
            }

            char = self.content[self.curr];
            if (self.curr + 1 == self.size and char == '}') {
                std.debug.print("{s}\n", .{self.content});
                return;
            }
            if (char == ',') {
                self.curr += 1;
                repeat = true;
                continue;
            }
            if (char == '}') {
                self.curr += 1;
                self.trim_space();
                char = self.content[self.curr];
                if (char == ',') {
                    self.curr += 1;
                    repeat = true;
                    continue;
                }

                std.debug.print("Expected comma (,), but found \"{c}\" at {d}.\n", .{char, self.curr});
                return;
            }

            std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, self.content[self.curr]});
        }
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try fs.cwd().openFile("test.json", .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    if (file_size == 0) {
        std.debug.print("EMPTY\n", .{});
        return;
    }

    var reader = Reader{
        .size = file_size - 1, // remove eof char
        .content = buffer[0..file_size - 1],
        .curr = 0,
    };

    reader.parse();
}

