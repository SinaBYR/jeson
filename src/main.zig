const std = @import("std");
const fs = @import("std").fs;
const ascii = @import("std").ascii;
const expect = @import("std").testing.expect;

const Reader = struct {
    content: []u8,
    curr: u32,
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
        .content = buffer[0..file_size],
        .curr = 0,
    };

    var char = reader.content[reader.curr];
    if (char != '{') {
        std.debug.print("1Unexpected character at {d}: {c}\n", .{reader.curr, char});
        return;
    }

    if (reader.curr + 1 > file_size - 1) {
        std.debug.print("2Unexpected character at {d}: {c}\n", .{reader.curr, char});
        return;
    }

    reader.curr += 1;
    char = reader.content[reader.curr];
    if (char == '}') {
        std.debug.print("json: {s}\n", .{reader.content});
        return;
    }

    var repeat = true;
    while(repeat) {
        repeat = false;

        char = reader.content[reader.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        char = reader.content[reader.curr];

        var curr_temp = reader.curr;
        while (ascii.isAlphabetic(reader.content[reader.curr])) {
            reader.curr += 1;
        }

        if (curr_temp == reader.curr) {
            std.debug.print("Field name cannot be empty\n", .{});
            return;
        }

        char = reader.content[reader.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        char = reader.content[reader.curr];
        if (char != ':') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        char = reader.content[reader.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        char = reader.content[reader.curr];

        curr_temp = reader.curr;
        while (ascii.isAlphabetic(reader.content[reader.curr])) {
            reader.curr += 1;
        }

        char = reader.content[reader.curr];
        if (char != '"') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        if (reader.curr + 1 > file_size - 1) {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        char = reader.content[reader.curr];
        if (char == '}') {
            std.debug.print("json: {s}\n", .{reader.content});
            return;
        }

        if (char != ',') {
            std.debug.print("Unexpected character at {d}: {c}\n", .{reader.curr, char});
            return;
        }

        reader.curr += 1;
        repeat = true;
    }
}

