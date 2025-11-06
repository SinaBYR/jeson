const std = @import("std");
const fs = @import("std").fs;
const ascii = @import("std").ascii;
const expect = @import("std").testing.expect;

const Reader = struct {
    size: u64,
    content: []u8,
    curr: u32,
    fn trim_space(self: *Reader) void {
        std.debug.print("self.curr: {d}\n", .{self.curr});
        while(ascii.isWhitespace(self.content[self.curr])) {
            self.curr += 1;
        }
    }

    fn parse_numeric(self: *Reader) void {
        while(self.curr < self.size and ascii.isDigit(self.content[self.curr])) {
            self.curr += 1;
        }
    }

    fn parse_value(self: *Reader) void {
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
                return;
            }
            self.curr += 1;
        } else {
            if (char == '[') {
                // while(self.curr < file_size and (ascii.))

            } else {
                self.parse_numeric();
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
            self.trim_space();
            self.parse_key();
            self.trim_space();

            char = self.content[self.curr];
            if (char != ':') {
                std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
                return;
            }
            self.curr += 1;

            self.trim_space();
            self.parse_value();
            self.trim_space();

            if (self.curr + 1 > self.size) {
                std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
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
            } else {
                std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
                return;
            }
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

    const bytes_read = try file.readAll(buffer);
    std.debug.print("Read {d} bytes with space removed\n", .{bytes_read - 1});

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

