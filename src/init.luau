local width = if _G.UNICODE_WIDTH_CJK ~= false
    then require('./strWidthCjk')
    else require('./strWidth')

return {
    width = width :: (string) -> number,
}
