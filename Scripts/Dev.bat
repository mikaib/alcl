@echo off
call Scripts/Env
haxe build.hxml
hl Binary/Hashlink/out.hl -cwd ./Env -output ./Out/Dev -std C:/projects/ALCL/Stdlib main.alcl