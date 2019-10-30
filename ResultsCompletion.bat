@echo Resizing...
cls
mode 1000,600
mode con lines=32000
powershell.exe -executionpolicy bypass -Sta -noexit -file %~dp0ResultsCompletion.ps1 
sleep(100)
