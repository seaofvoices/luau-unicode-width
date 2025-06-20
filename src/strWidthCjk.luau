local SOLIDUS_TRANSPARENT = require('./SOLIDUS_TRANSPARENT')
local WIDTH = require('./WIDTH')
local WIDTH_CJK = require('./WIDTH_CJK')
local WidthInfo = require('./WidthInfo')
local isEmojiModifierBase = require('./isEmojiModifierBase')
local isLigatureTransparent = require('./isLigatureTransparent')
local startsEmojiPresentationSeq = require('./startsEmojiPresentationSeq')

type WidthInfo = WidthInfo.WidthInfo

-- Whether this character is transparent wrt the effect of
-- U+0338 COMBINING LONG SOLIDUS OVERLAY
-- on its base character.
local function isSolidusTransparent(c: number): boolean
    -- deviation: c is already a number
    local cp = c

    if isLigatureTransparent(c) then
        return true
    end

    -- deviate: use a linear search instead of a binary search
    for _, pair in SOLIDUS_TRANSPARENT do
        local lo = pair[1]
        local hi = pair[2]

        -- deviation: replace from_le_bytes
        local lo = bit32.bor(lo[1], bit32.lshift(lo[2], 8), bit32.lshift(lo[3], 16))
        local hi = bit32.bor(hi[1], bit32.lshift(hi[2], 8), bit32.lshift(hi[3], 16))

        if cp >= lo and cp <= hi then
            return true
        end
    end

    return false
end

-- Returns the [UAX #11](https://www.unicode.org/reports/tr11/) based width of `c` by
-- consulting a multi-level lookup table.
--
-- # Maintenance
-- The tables themselves are autogenerated but this function is hardcoded. You should have
-- nothing to worry about if you re-run `unicode.py` (for example, when updating Unicode.)
-- However, if you change the *actual structure* of the lookup tables (perhaps by editing the
-- `make_tables` function in `unicode.py`) you must ensure that this code reflects those changes.
local function lookupWidthCjk(c: number): (number, WidthInfo)
    -- deviation: c is already a number
    local cp = c

    local t1Offset = WIDTH_CJK.ROOT_CJK[1 + bit32.rshift(cp, 13)]

    -- Each sub-table in WIDTH_MIDDLE is 7 bits, and each stored entry is a byte,
    -- so each sub-table is 128 bytes in size.
    -- (Sub-tables are selected using the computed offset from the previous table.)
    local t2Offset = WIDTH.MIDDLE[1 + t1Offset][1 + bit32.band(bit32.rshift(cp, 7), 0x3F)]

    -- Each sub-table in WIDTH_LEAVES is 6 bits, but each stored entry is 2 bits.
    -- This is accomplished by packing four stored entries into one byte.
    -- So each sub-table is 2**(7-2) == 32 bytes in size.
    -- Since this is the last table, each entry represents an encoded width.
    local packedWidths = WIDTH.LEAVES[1 + t2Offset][1 + bit32.band(bit32.rshift(cp, 2), 0x1F)]

    -- Extract the packed width
    local width = bit32.band(bit32.rshift(packedWidths, 2 * bit32.band(cp, 0b11)), 0b11)

    if width < 3 then
        return width, WidthInfo.DEFAULT
    else
        if c == 0xA then
            return 1, WidthInfo.LINE_FEED
        elseif c == 0x338 then
            return 0, WidthInfo.COMBINING_LONG_SOLIDUS_OVERLAY :: number
        elseif c == 0x5DC then
            return 1, WidthInfo.HEBREW_LETTER_LAMED
        elseif c >= 0x622 and c <= 0x882 then
            return 1, WidthInfo.JOINING_GROUP_ALEF
        elseif c >= 0x1780 and c <= 0x17AF then
            return 1, WidthInfo.KHMER_COENG_ELIGIBLE_LETTER
        elseif c == 0x17D8 then
            return 3, WidthInfo.DEFAULT
        elseif c == 0x1A10 then
            return 1, WidthInfo.BUGINESE_LETTER_YA
        elseif c >= 0x2D31 and c <= 0x2D6F then
            return 1, WidthInfo.TIFINAGH_CONSONANT
        elseif c >= 0xA4FC and c <= 0xA4FD then
            return 1, WidthInfo.LISU_TONE_LETTER_MYA_NA_JEU
        elseif c == 0xFE0F then
            return 0, WidthInfo.VARIATION_SELECTOR_16
        elseif c == 0x10C03 then
            return 1, WidthInfo.OLD_TURKIC_LETTER_ORKHON_I
        elseif c >= 0x1F1E6 and c <= 0x1F1FF then
            return 1, WidthInfo.REGIONAL_INDICATOR
        elseif c >= 0x1F3FB and c <= 0x1F3FF then
            return 2, WidthInfo.EMOJI_MODIFIER
        else
            return 2, WidthInfo.EMOJI_PRESENTATION
        end
    end
end

-- Returns the [UAX #11](https://www.unicode.org/reports/tr11/) based width of `c`.
-- Ambiguous width characters are treated as wide.
local function widthInStrCjk(c: number, nextInfo: WidthInfo): (number, WidthInfo)
    if WidthInfo.isEmojiPresentation(nextInfo) then
        if startsEmojiPresentationSeq(c) then
            local width = if WidthInfo.isZwjEmojiPresentation(nextInfo) then 0 else 2

            return width, WidthInfo.EMOJI_PRESENTATION
        else
            nextInfo = WidthInfo.unsetEmojiPresentation(nextInfo)
        end
    end

    local s = utf8.char(c)

    if
        (
            nextInfo == WidthInfo.COMBINING_LONG_SOLIDUS_OVERLAY
            or nextInfo == WidthInfo.SOLIDUS_OVERLAY_ALEF
        ) and (s == '<' or s == '=' or s == '>')
    then
        return 2, WidthInfo.DEFAULT
    end

    if c <= 0xA0 then
        if s == '\n' then
            return 1, WidthInfo.LINE_FEED
        elseif s == '\r' and nextInfo == WidthInfo.LINE_FEED then
            return 0, WidthInfo.DEFAULT
        else
            return 1, WidthInfo.DEFAULT
        end
    else
        -- Fast path

        if nextInfo ~= WidthInfo.DEFAULT then
            if s == '\u{FE0F}' then
                return 0, WidthInfo.setEmojiPresentation(nextInfo)
            end

            if WidthInfo.isLigatureTransparent(nextInfo) then
                if s == '\u{200D}' then
                    return 0, WidthInfo.setZwjBit(nextInfo)
                elseif isLigatureTransparent(c) then
                    return 0, nextInfo
                end
            end

            if nextInfo == WidthInfo.COMBINING_LONG_SOLIDUS_OVERLAY and isSolidusTransparent(c) then
                return lookupWidthCjk(c), WidthInfo.COMBINING_LONG_SOLIDUS_OVERLAY :: number
            elseif nextInfo == WidthInfo.JOINING_GROUP_ALEF and c == 0x0338 then
                return 0, WidthInfo.SOLIDUS_OVERLAY_ALEF :: number

            -- Arabic Lam-Alef ligature
            elseif
                (
                    nextInfo == WidthInfo.JOINING_GROUP_ALEF
                    or nextInfo == WidthInfo.SOLIDUS_OVERLAY_ALEF
                )
                and (
                    c == 0x644
                    or (c >= 0x6B5 and c <= 0x6B8)
                    or c == 0x76A
                    or c == 0x8A6
                    or c == 0x8C7
                )
            then
                return 0, WidthInfo.DEFAULT

            -- Hebrew Alef-ZWJ-Lamed ligature
            elseif nextInfo == WidthInfo.ZWJ_HEBREW_LETTER_LAMED and c == 0x05D0 then
                return 0, WidthInfo.DEFAULT

            -- Khmer coeng signs
            elseif nextInfo == WidthInfo.KHMER_COENG_ELIGIBLE_LETTER and c == 0x17D2 then
                return -1, WidthInfo.DEFAULT

            -- Buginese <a, -i> ZWJ ya ligature
            elseif nextInfo == WidthInfo.ZWJ_BUGINESE_LETTER_YA and c == 0x1A17 then
                return 0, WidthInfo.BUGINESE_VOWEL_SIGN_I_ZWJ_LETTER_YA
            elseif nextInfo == WidthInfo.BUGINESE_VOWEL_SIGN_I_ZWJ_LETTER_YA and c == 0x1A15 then
                return 0, WidthInfo.DEFAULT

            -- Tifinagh bi-consonants
            elseif
                (
                    nextInfo == WidthInfo.TIFINAGH_CONSONANT
                    or nextInfo == WidthInfo.ZWJ_TIFINAGH_CONSONANT
                ) and c == 0x2D7F
            then
                return 1, WidthInfo.TIFINAGH_JOINER_CONSONANT
            elseif
                nextInfo == WidthInfo.ZWJ_TIFINAGH_CONSONANT
                and ((c >= 0x2D31 and c <= 0x2D65) or c == 0x2D6F)
            then
                return 0, WidthInfo.DEFAULT
            elseif
                nextInfo == WidthInfo.TIFINAGH_JOINER_CONSONANT
                and ((c >= 0x2D31 and c <= 0x2D65) or c == 0x2D6F)
            then
                return -1, WidthInfo.DEFAULT

            -- Lisu tone letter combinations
            elseif
                nextInfo == WidthInfo.LISU_TONE_LETTER_MYA_NA_JEU and (c >= 0xA4F8 and c <= 0xA4FB)
            then
                return 0, WidthInfo.DEFAULT

            -- Old Turkic ligature
            elseif nextInfo == WidthInfo.ZWJ_OLD_TURKIC_LETTER_ORKHON_I and c == 0x10C32 then
                return 0, WidthInfo.DEFAULT

            -- Emoji modifier
            elseif nextInfo == WidthInfo.EMOJI_MODIFIER and isEmojiModifierBase(c) then
                return 0, WidthInfo.EMOJI_PRESENTATION

            -- Regional indicator
            elseif
                (
                    nextInfo == WidthInfo.REGIONAL_INDICATOR
                    or nextInfo == WidthInfo.SEVERAL_REGIONAL_INDICATOR
                ) and (c >= 0x1F1E6 and c <= 0x1F1FF)
            then
                return 1, WidthInfo.SEVERAL_REGIONAL_INDICATOR

            -- ZWJ emoji
            elseif
                (
                    nextInfo == WidthInfo.EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.SEVERAL_REGIONAL_INDICATOR
                    or nextInfo == WidthInfo.EVEN_REGIONAL_INDICATOR_ZWJ_PRESENTATION
                    or nextInfo == WidthInfo.ODD_REGIONAL_INDICATOR_ZWJ_PRESENTATION
                    or nextInfo == WidthInfo.EMOJI_MODIFIER
                ) and c == 0x200D
            then
                return 0, WidthInfo.ZWJ_EMOJI_PRESENTATION
            elseif nextInfo == WidthInfo.ZWJ_EMOJI_PRESENTATION and c == 0x20E3 then
                return 0, WidthInfo.KEYCAP_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.VS16_ZWJ_EMOJI_PRESENTATION and startsEmojiPresentationSeq(c)
            then
                return 0, WidthInfo.EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.VS16_KEYCAP_ZWJ_EMOJI_PRESENTATION
                and (
                    (c >= string.byte('0') and c <= string.byte('9'))
                    or c == string.byte('#')
                    or c == string.byte('*')
                )
            then
                return 0, WidthInfo.KEYCAP_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.ZWJ_EMOJI_PRESENTATION and (c >= 0x1F1E6 and c <= 0x1F1FF)
            then
                return 1, WidthInfo.REGIONAL_INDICATOR_ZWJ_PRESENTATION
            elseif
                (
                    nextInfo == WidthInfo.REGIONAL_INDICATOR_ZWJ_PRESENTATION
                    or nextInfo == WidthInfo.ODD_REGIONAL_INDICATOR_ZWJ_PRESENTATION
                ) and (c >= 0x1F1E6 and c <= 0x1F1FF)
            then
                return -1, WidthInfo.EVEN_REGIONAL_INDICATOR_ZWJ_PRESENTATION
            elseif
                nextInfo == WidthInfo.EVEN_REGIONAL_INDICATOR_ZWJ_PRESENTATION
                and (c >= 0x1F1E6 and c <= 0x1F1FF)
            then
                return 3, WidthInfo.ODD_REGIONAL_INDICATOR_ZWJ_PRESENTATION
            elseif
                nextInfo == WidthInfo.ZWJ_EMOJI_PRESENTATION and (c >= 0x1F3FB and c <= 0x1F3FF)
            then
                return 0, WidthInfo.EMOJI_MODIFIER
            elseif nextInfo == WidthInfo.ZWJ_EMOJI_PRESENTATION and c == 0xE007F then
                return 0, WidthInfo.TAG_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0061 and c <= 0xE007A)
            then
                return 0, WidthInfo.TAG_A1_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_A1_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0061 and c <= 0xE007A)
            then
                return 0, WidthInfo.TAG_A2_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_A2_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0061 and c <= 0xE007A)
            then
                return 0, WidthInfo.TAG_A3_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_A3_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0061 and c <= 0xE007A)
            then
                return 0, WidthInfo.TAG_A4_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_A4_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0061 and c <= 0xE007A)
            then
                return 0, WidthInfo.TAG_A5_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_A5_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0061 and c <= 0xE007A)
            then
                return 0, WidthInfo.TAG_A6_END_ZWJ_EMOJI_PRESENTATION
            elseif
                (
                    nextInfo == WidthInfo.TAG_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A1_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A2_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A3_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A4_END_ZWJ_EMOJI_PRESENTATION
                ) and (c >= 0xE0030 and c <= 0xE0039)
            then
                return 0, WidthInfo.TAG_D1_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_D1_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0030 and c <= 0xE0039)
            then
                return 0, WidthInfo.TAG_D2_END_ZWJ_EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.TAG_D2_END_ZWJ_EMOJI_PRESENTATION
                and (c >= 0xE0030 and c <= 0xE0039)
            then
                return 0, WidthInfo.TAG_D3_END_ZWJ_EMOJI_PRESENTATION
            elseif
                (
                    nextInfo == WidthInfo.TAG_A3_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A4_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A5_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_A6_END_ZWJ_EMOJI_PRESENTATION
                    or nextInfo == WidthInfo.TAG_D3_END_ZWJ_EMOJI_PRESENTATION
                ) and c == 0x1F3F4
            then
                return 0, WidthInfo.EMOJI_PRESENTATION
            elseif
                nextInfo == WidthInfo.ZWJ_EMOJI_PRESENTATION
                and select(lookupWidthCjk(c), 2) == WidthInfo.EMOJI_PRESENTATION
            then
                return 0, WidthInfo.EMOJI_PRESENTATION
            else
                --  Fallback
            end
        end

        local ret0, ret1 = lookupWidthCjk(c)

        return ret0, ret1
    end
end

local function strWidthCjk(s: string): number
    local length = utf8.len(s)
    if length == nil then
        error('Invalid UTF-8 string')
    end

    local reversedChars = table.create(length)
    local i = length

    for _, code in utf8.codes(s) do
        reversedChars[i] = code
        i -= 1
    end

    local sum = 0
    local nextInfo = WidthInfo.DEFAULT

    for _, code in reversedChars do
        local add, info = widthInStrCjk(code, nextInfo)
        sum += add
        nextInfo = info
    end

    return sum
end

return strWidthCjk
