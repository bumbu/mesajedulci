# Mesaje Dulci

![Page Demo](http://bumbu.github.io/mesajedulci/demo.jpg)

A single web page featuring:
- 5 Custom image fonts
- Live typing with image fonts
- Optimizing original images (gulp)
- Spriting images for web (gulp)
- Rendering messages on server
- Storing messages on server

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

Running `gulp images` will minimize and optimize images and move them into `public/fonts` folder.
It will also generate a `public/js/fonts.json` file with data about fonts.

Running `gulp images-sprite` will join images into sprites (used for web).

## License

[GNU Public License](http://www.gnu.org/licenses/gpl-3.0.html) (GPL v3)
