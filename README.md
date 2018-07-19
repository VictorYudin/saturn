This repo is a Windows build recipe for [Pixar
USD](https://github.com/PixarAnimationStudios/USD). The recipe is automatically
validated and the binaries are ready to do download thanks to
[AppVeyor](https://www.appveyor.com/).

[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/VictorYudin/saturn?branch=master&svg=true)](https://ci.appveyor.com/project/VictorYudin/saturn/branch/master)

[Universal Scene Description
(USD)](https://github.com/PixarAnimationStudios/USD), is a system that scalably
encodes and interchanges geometry and shading data between Digital Content
Creation applications.

## Something else?
USD has a number of dependencies. Thus, the building script also contains the
recipes for building lots of VFX (and other) libraries:
* boost
* embree
* freeglut
* freetype
* glew
* glfw
* ilmbase
* jpeg
* libpng
* oiio
* openexr
* opensubdiv
* png
* ptex
* tbb
* tiff
* usd
* zlib

## What's included?
USD monolithic library, Python stuff, UsdView and Maya 2018 plugin. It's built
with Visual Studio 2017 v15.x and linked with the static version of the run-time
library.
