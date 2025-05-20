local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local unicodeWidth = require('../init')

local expect = jestGlobals.expect
local it = jestGlobals.it

local cases: { [string]: number } = {
    ['A'] = 1,
    ['\n'] = 1,
    ['\r\n'] = 1,
    ['Ｈｅｌｌｏ, ｗｏｒｌｄ!'] = 23,
    ['👩'] = 2,
    ['👩👩👧👧'] = 8,
}

for text, width in cases do
    it(`calculates a width of {width} for '{text}'`, function()
        expect(unicodeWidth.width(text)).toEqual(width)
    end)
end
