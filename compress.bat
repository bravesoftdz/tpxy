@echo off

copy installsvc.bat Win32\Release
copy installsvc.bat Win64\Release
copy uninstallsvc.bat Win32\Release
copy uninstallsvc.bat Win64\Release
copy README.md Win32\Release
copy LICENSE Win32\Release
copy README.md Win64\Release
copy LICENSE Win64\Release

if exist tpxy-win32.zip del tpxy-win32.zip
cd Win32\Release
"%PROGRAMFILES%\7-Zip\7z.exe" a -tzip ..\..\tpxy-win32.zip *.exe *.bat *svc.ini rules.ini README.md LICENSE
cd ..\..

if exist tpxy-win64.zip del tpxy-win64.zip
cd Win64\Release
"%PROGRAMFILES%\7-Zip\7z.exe" a -tzip ..\..\tpxy-win64.zip *.exe *.bat *svc.ini rules.ini README.md LICENSE
cd ..\..
