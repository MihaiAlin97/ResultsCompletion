@echo Resizing...
cls
mode 1000,600
powershell.exe -executionpolicy bypass -Sta -noexit -file %~dp0ResultsCompletion.ps1 