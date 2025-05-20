local EMOJI_MODIFIER_LEAVES = require('./EMOJI_MODIFIER_LEAVES')

-- Returns `true` if `c` is an `Emoji_Modifier_Base`.
local function isEmojiModifierBase(c: number): boolean
    -- deviation: c is already a number
    local cp = c

    --First level of lookup uses all but 8 LSB

    local topBits = bit32.rshift(cp, 8)

    local leaf: { { number } }? = if topBits == 0x26
        then EMOJI_MODIFIER_LEAVES['0']
        elseif topBits == 0x27 then EMOJI_MODIFIER_LEAVES['1']
        elseif topBits == 0x1F3 then EMOJI_MODIFIER_LEAVES['2']
        elseif topBits == 0x1F4 then EMOJI_MODIFIER_LEAVES['3']
        elseif topBits == 0x1F5 then EMOJI_MODIFIER_LEAVES['4']
        elseif topBits == 0x1F6 then EMOJI_MODIFIER_LEAVES['5']
        elseif topBits == 0x1F9 then EMOJI_MODIFIER_LEAVES['6']
        elseif topBits == 0x1FA then EMOJI_MODIFIER_LEAVES['7']
        else nil

    if leaf == nil then
        return false
    end

    local bottomBits = bit32.band(cp, 0xFF)

    -- deviate: use a linear search instead of a binary search
    for _, pair in leaf do
        local lo = pair[1]
        local hi = pair[2]
        if bottomBits >= lo and bottomBits <= hi then
            return true
        end
    end

    return false
end

return isEmojiModifierBase
