@echo off
call Scripts/Env
haxe build.hxml
hl Binary/Hashlink/out.hl -compile cmake -cwd ./Env -output ./Out/Dev -std ../Stdlib main.alcl