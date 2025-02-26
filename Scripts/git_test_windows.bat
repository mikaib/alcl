@echo off
echo Running tests...
echo Current directory: %CD%

cd /d Tests
(for /r %%F in (*) do @echo %%~nxF) > test_files.txt
cd /d ..

setlocal enabledelayedexpansion
set TEST_FILES=
for /f "delims=" %%F in (Tests\test_files.txt) do (
    set TEST_FILES=!TEST_FILES! %%F
)

echo Test files:
for %%F in (!TEST_FILES!) do echo - %%F

./ALCL.exe -cwd ./Tests -compile cmake -std ../Stdlib -output ../Env/Out/Tests !TEST_FILES!
echo Tests generated!

endlocal