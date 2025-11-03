const std = @import("std");
const fs = @import("std").fs;
const ascii = @import("std").ascii;
const expect = @import("std").testing.expect;

const Reader = struct {
    file_size: u64,
    content: []u8,
    curr: u32,
    fn trim_space(self: *Reader) void {
        while(ascii.isWhitespace(self.content[self.curr])) {
            self.curr += 1;
        }
    }

    fn parse_numeric(self: *Reader) void {
        while(self.curr < self.file_size and ascii.isDigit(self.content[self.curr])) {
            self.curr += 1;
        }
    }

    fn parse_string(self: *Reader, is_key: bool) void {
        if (is_key) {
            while (ascii.isAlphabetic(self.content[self.curr])) {
                self.curr += 1;
            }
        } else {
            while (ascii.isAlphanumeric(self.content[self.curr])) {
                self.curr += 1;
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
        self.parse_string(true);

        if (curr_temp == self.curr) {
            std.debug.print("Field name cannot be empty\n", .{});
            return;
        }

        char = self.content[self.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{self.curr, char});
            return;
        }
    }
};


pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const file = try fs.cwd().openFile("test.json", .{});
    defer file.close();

    var file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    const bytes_read = try file.readAll(buffer);
    std.debug.print("Read {d} bytes\n", .{bytes_read});

    if (file_size == 0) {
        std.debug.print("EMPTY\n", .{});
        return;
    }

    // get rid of end of file spcae character
    file_size -= 1;

    var reader = Reader{
        .file_size = file_size,
        .content = buffer[0..file_size],
        .curr = 0,
    };

    var char = reader.content[reader.curr];
    if (char != '{') {
        std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
        return;
    }

    if (reader.curr + 1 > file_size) {
        std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
        return;
    }

    reader.curr += 1;
    reader.trim_space();
    char = reader.content[reader.curr];
    if (char == '}') {
        std.debug.print("json: {s}\n", .{reader.content});
        return;
    }

    var repeat = true;
    while(repeat) {
        repeat = false;

        reader.parse_key();

        reader.curr += 1;
        reader.trim_space();

        char = reader.content[reader.curr];
        if (char != ':') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        reader.trim_space();
        char = reader.content[reader.curr];
        if (char == '"') {
            reader.curr += 1;
            char = reader.content[reader.curr];

            reader.parse_string(false);

            char = reader.content[reader.curr];
            if (char != '"') {
                std.debug.print("Missing double quote \" at {d}\n", .{reader.curr});
                return;
            }
            reader.curr += 1;
        } else {
            if (char == '[') {
                // while(reader.curr < file_size and (ascii.))

            } else {
                reader.parse_numeric();
            }
        }

        reader.trim_space();

        if (reader.curr + 1 > file_size) {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        char = reader.content[reader.curr];
        if (reader.curr + 1 == file_size and char == '}') {
            std.debug.print("json: {s}\n", .{reader.content});
            return;
        }

        reader.curr += 1;
        reader.trim_space();
        repeat = true;
    }
}

