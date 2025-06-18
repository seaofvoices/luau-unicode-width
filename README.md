<div align="center">

[![checks](https://github.com/seaofvoices/luau-unicode-width/actions/workflows/test.yml/badge.svg)](https://github.com/seaofvoices/luau-unicode-width/actions/workflows/test.yml)
![version](https://img.shields.io/github/package-json/v/seaofvoices/luau-unicode-width)
[![GitHub top language](https://img.shields.io/github/languages/top/seaofvoices/luau-unicode-width)](https://github.com/luau-lang/luau)
![license](https://img.shields.io/npm/l/luau-unicode-width)
![npm](https://img.shields.io/npm/dt/luau-unicode-width)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/seaofvoices)

</div>

# luau-unicode-width

A Luau port of the Rust [`unicode-width` module](https://docs.rs/unicode-width/0.2.0/unicode_width/index.html) that provides Unicode character width calculations. This package helps determine the displayed width of Unicode characters and strings, useful for terminal applications.

**Note:** This library does not compute the displayed width based on fonts - it only provides the standardized Unicode width properties as defined in the [Unicode Standard Annex #11](https://www.unicode.org/reports/tr11/)

## Installation

Add `luau-unicode-width` in your dependencies:

```bash
yarn add luau-unicode-width
```

Or if you are using `npm`:

```bash
npm install luau-unicode-width
```

Artifacts can also be downloaded from the [releases page](https://github.com/seaofvoices/luau-unicode-width/releases).

## Content

The package contains a single function named `width`.

```lua
local unicodeWidth = require("@pkg/luau-unicode-width")

local width = unicodeWidth.width("Ｈｅｌｌｏ, ｗｏｒｌｄ!")
```

For more information about how width is calculated, take a look at [the rules section of the Rust module](https://docs.rs/unicode-width/0.2.0/unicode_width/index.html#rules-for-determining-width).

### Chinese-Japanese-Korean Characters

The `cjk` feature from the original Rust crate was converted to Luau using a global variable. To disable support, set the `UNICODE_WIDTH_CJK` to `false`. Make sure to do that before calling `require` on the package.

## License

This project is available under the MIT license. See [LICENSE.txt](LICENSE.txt) for details.

## Other Lua Environments Support

If you would like to use this library on a Lua environment, where it is currently incompatible, open an issue (or comment on an existing one) to request the appropriate modifications.

The library uses [darklua](https://github.com/seaofvoices/darklua) to process its code.
