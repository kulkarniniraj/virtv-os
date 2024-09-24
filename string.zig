pub fn concat(input: []const []const u8, output: []u8) !usize {
    var total: usize = 0;
    for (input) |str| {
        total += str.len;
    }
    if (total > output.len) {
        return error.TooBig;
    }

    var i: usize = 0;
    for (input) |str| {
        for(str) |char| {
            output[i] = char;
            i += 1;
        }
    }

    return i;
}