local EMOJI_PRESENTATION_LEAVES = require('./EMOJI_PRESENTATION_LEAVES')
local WidthInfo = require('./WidthInfo')

type WidthInfo = WidthInfo.WidthInfo

-- Whether this character forms an [emoji presentation sequence]
-- (https://www.unicode.org/reports/tr51/#def_emoji_presentation_sequence)
-- when followed by `'\u{FEOF}'`.
-- Emoji presentation sequences are considered to have width 2.
local function startsEmojiPresentationSeq(c: number): boolean
    -- deviation: c is already a number
    local cp = c

    -- First level of lookup uses all but 10 LSB
    local topBits = bit32.rshift(cp, 10)

    local idxOfLeaf: number? = if topBits == 0x0
        then 0
        elseif topBits == 0x8 then 1
        elseif topBits == 0x9 then 2
        elseif topBits == 0xA then 3
        elseif topBits == 0xC then 4
        elseif topBits == 0x7C then 5
        elseif topBits == 0x7D then 6
        else nil

    if idxOfLeaf == nil then
        return false
    end

    -- Extract the 3-9th (0-indexed) least significant bits of `cp`,
    -- and use them to index into `leaf_row`.
    local idxWithinLeaf = bit32.band(bit32.rshift(cp, 3), 0x7F)

    local leafByte = EMOJI_PRESENTATION_LEAVES[idxOfLeaf][idxWithinLeaf]

    -- Use the 3 LSB of `cp` to index into `leafByte`.
    return bit32.band(bit32.rshift(leafByte, bit32.band(cp, 7)), 1) == 1
end

return startsEmojiPresentationSeq
