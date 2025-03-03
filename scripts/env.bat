@echo off
if not exist Env (
    mkdir Env
    > Env\main.alcl echo need "io"
    >> Env\main.alcl echo.
    >> Env\main.alcl echo func main^(^)^: Void {
    >> Env\main.alcl echo     println^(^"Hello, World!^"^)
    >> Env\main.alcl echo }
)
