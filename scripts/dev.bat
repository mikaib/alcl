@echo off
call Scripts/Env
haxe build.hxml
hl binary/hashlink/out.hl -cwd ./env -output ./out/dev -compile cmake -std ../nostd main.alcl