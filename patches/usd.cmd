@echo off

pushd %~dp0
set USD_INSTALL_ROOT=%CD%
popd

setlocal

set PATH=%PATH%;%USD_INSTALL_ROOT%\lib
set PATH=%PATH%;%USD_INSTALL_ROOT%\..\boost\lib
set PATH=%PATH%;%USD_INSTALL_ROOT%\bin
set PATH=%PATH%;C:\Python27

set PYTHONPATH=%PYTHONPATH%;%USD_INSTALL_ROOT%\lib\python

set PXR_PLUGINPATH_NAME=%PXR_PLUGINPATH_NAME%;%USD_INSTALL_ROOT%\share\usd\plugins

%*

endlocal
