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
* alembic
* boost
* freetype
* glew
* glfw
* glut
* hdf5
* ilmbase
* jpeg
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
USD monolithic library, Python stuff, UsdView and Maya 2016 plugin. It's built
with Visual Studio 2017 v15.4 and linked with the static version of the run-time
library.

### Why Maya 2016?
Because Maya 2016 API is available to direct download. If
you know how to download Maya 201x API, please let me know and I update it.
