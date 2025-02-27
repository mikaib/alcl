@echo off
echo Running tests...
echo Current directory: %CD%

cd /d Tests
setlocal enabledelayedexpansion
set TEST_FILES=
for /r %%F in (*) do (
    set FILE=%%~nxF
    set TEST_FILES=!TEST_FILES! !FILE!
)
cd /d ..

echo Test files:
for %%F in (!TEST_FILES!) do echo - %%F

ALCL -verbose yes -cwd ./Tests -compile cmake -std ../Stdlib -output ../Env/Out/Tests !TEST_FILES!
echo Tests generated!

endlocal