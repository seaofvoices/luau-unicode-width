-- Whether this character is a default-ignorable combining mark
-- or ZWJ. These characters won't interrupt non-Arabic ligatures.
local function isLigatureTransparent(c: number): boolean
    return c == 0x34F
        or c >= 0x17B4 and c <= 0x17B5
        or c >= 0x180B and c <= 0x180D
        or c == 0x180F
        or c == 0x200D
        or c >= 0xFE00 and c <= 0xFE0F
        or c >= 0xE0100 and c <= 0xE01EF
end

return isLigatureTransparent
