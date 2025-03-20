@echo off
call Scripts/Env
haxe build.hxml
hl binary/hashlink/out.hl -compile cmake -cwd ./env -output ./out/dev -std ../stdlib main.alcl