# Mesaje Dulci

![Page Demo](http://bumbu.github.io/mesajedulci/demo.jpg)

A single web page featuring:
- 5 Custom image fonts
- Live typing with image fonts
- Optimizing original images (gulp)
- Spriting images for web (gulp)
- Rendering messages on server
- Storing messages on server

## Prerequisites

* Imagemagic
* Gulp.js

## Quick Start

You should have a `app/font` folder that will contain at least one subfolder with font letters.
It should look like:
* app
  * font
    * font1
      * A.jpg
      * B.jpg
      * ...
    * font2
      * A.jpg
      * B.jpg
      * ...

Run `gulp client` to compile client assets.
Run `gulp server` to compile serve assets.

Client gets images of width 240, while server gets images of width 120.
You can change that in gulp file (will also require changing a variable on server).


## Useful commands

Cut 210 pixels from bottom side of all images in current folder
`find . -type f -exec mogrify -gravity South -chop 0x210 {} \;`


## Test strings

abcdefghijklm
nopqrstuvwxyz
0123456789
-=+:,.!?()<>
ășțâî

abcdefghijklm\nnopqrstuvwxyz\n0123456789\n-=+:,.!?()<>\nășțâî


## License

[GNU Public License](http://www.gnu.org/licenses/gpl-3.0.html) (GPL v3)
