# uahgi

another experimential typesetting tool

## Known issues
- Some .ttc file(eg. Noto Sans/Serif CJK) can't be loaded. It seems to be a libharu bug. For those want to use Noto Sans/Serif CJK, please download the .ttf file on Google Fonts. [Example (Trad. Chinese Version)](https://fonts.google.com/noto/specimen/Noto+Sans+TC)

## How to test
To test with the example, please using the command:

```
cd /path/to/uahgi
julia --project="." src/uahgi.jl example/ex1.ug
```

## Origin of the name
The name is after the Taiwanese/Hokkien word for the movable type, which is ua̍h-gī (活字), in Taichung-Basin accent.