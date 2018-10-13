
set SATURN_BASE=%cd%

rem Using the Registry
rem Press the Windows Key + R, type in regedit in the Run dialog box and click
rem OK to open the Windows Registry.  In the Registry Editor, navigate to
rem HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender If you see a
rem registry entry named DisableAntiSpyware, double click to edit it and change
rem its value to 1.

rem Windows has no built-in wget or curl, so we generate a VBS script to do the same
set DLOAD_SCRIPT=%SATURN_BASE%\download.vbs
echo Option Explicit                                                    >  %DLOAD_SCRIPT%
echo Dim args, http, fileSystem, adoStream, url, target, status         >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo Set args = Wscript.Arguments                                       >> %DLOAD_SCRIPT%
echo Set http = CreateObject("WinHttp.WinHttpRequest.5.1")              >> %DLOAD_SCRIPT%
echo url = args(0)                                                      >> %DLOAD_SCRIPT%
echo target = args(1)                                                   >> %DLOAD_SCRIPT%
echo WScript.Echo "Getting '" ^& target ^& "' from '" ^& url ^& "'..."  >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo http.Open "GET", url, False                                        >> %DLOAD_SCRIPT%
echo http.Send                                                          >> %DLOAD_SCRIPT%
echo status = http.Status                                               >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo If status ^<^> 200 Then                                            >> %DLOAD_SCRIPT%
echo    WScript.Echo "FAILED to download: HTTP Status " ^& status       >> %DLOAD_SCRIPT%
echo    WScript.Quit 1                                                  >> %DLOAD_SCRIPT%
echo End If                                                             >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo Set adoStream = CreateObject("ADODB.Stream")                       >> %DLOAD_SCRIPT%
echo adoStream.Open                                                     >> %DLOAD_SCRIPT%
echo adoStream.Type = 1                                                 >> %DLOAD_SCRIPT%
echo adoStream.Write http.ResponseBody                                  >> %DLOAD_SCRIPT%
echo adoStream.Position = 0                                             >> %DLOAD_SCRIPT%
echo.                                                                   >> %DLOAD_SCRIPT%
echo Set fileSystem = CreateObject("Scripting.FileSystemObject")        >> %DLOAD_SCRIPT%
echo If fileSystem.FileExists(target) Then fileSystem.DeleteFile target >> %DLOAD_SCRIPT%
echo adoStream.SaveToFile target                                        >> %DLOAD_SCRIPT%
echo adoStream.Close                                                    >> %DLOAD_SCRIPT%
echo.

echo Install base cygwin
cscript /nologo %DLOAD_SCRIPT% https://cygwin.com/setup-x86_64.exe setup-x86_64.exe
setup-x86_64 --no-admin --root %SATURN_BASE%\cygwin --quiet-mode --no-shortcuts --site http://cygwin.mirror.constant.com/ --categories Base -l %SATURN_BASE%\cygwin\var\cache\apt\packages --packages dos2unix,ncurses,wget,make,vim,ed,flex,bison,nasm,curl,unzip

set PATH=%PATH%;%SATURN_BASE%\cygwin\bin;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0

echo Install jom
curl --tlsv1.2 -o jom.tar.xz -L https://github.com/VictorYudin/saturn-jom/releases/download/1.0.5/jom-v1.1.2.tar.xz
tar -xf jom.tar.xz
set PATH=%PATH%;%SATURN_BASE%\jom\bin

echo Install python
curl https://www.python.org/ftp/python/2.7.13/python-2.7.13.amd64.msi -o python.msi
start /wait msiexec /a python.msi /qb TARGETDIR=%SATURN_BASE%\python
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python\python.exe get-pip.py
python\python.exe -m pip install PySide PyOpenGL Jinja2

"C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"

rem make BOOST_LINK=shared CRT_LINKAGE=shared PYTHON_BIN=python/python.exe usd -j2
