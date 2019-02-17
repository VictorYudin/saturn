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
* materialx
* oiio
* openexr
* opensubdiv
* osl
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

## Linux
The script works on CentOS 7. It requires the following packages.

```
sudo yum group install "Development Tools"
sudo yum install -y nasm ed python-devel mesa-libGL-devel mesa-libGLES-devel mesa-libEGL-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel mesa-libGLU-devel
```

## The environment for USD

### Maya

You need to add the path to the Maya plugin to the following environment
variable:

MAYA_MODULE_PATH | c:\usd\third_party\maya

### usdview

USD requires setting multiple environment variables. Saturn adds a windows
script that sets the required environment:

```
c:\usd\usd.cmd usdview c:\kitchen_set\Kitchen_set.usd
```

#### Python requirements

`usdview` requires [Python 2.7](https://www.python.org/downloads/) and several
preinstalled python packages. After installing Python, you can install the
packages with the following command:

```
c:\usd\usd.cmd python -m pip install PySide PyOpenGL Jinja2
```

