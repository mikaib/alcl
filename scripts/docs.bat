@echo off
call Scripts/Env
haxe build.hxml
hl binary/hashlink/out.hl -D docgen -std ./stdlib -output ./env/out/docs