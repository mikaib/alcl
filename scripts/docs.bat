@echo off
call Scripts/Env
haxe build.hxml
hl binary/hashlink/out.hl -D docgen -std ../stdlib -cwd ./env -output ./out/docs