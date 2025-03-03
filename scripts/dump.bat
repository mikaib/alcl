call Scripts/Env
haxe build.hxml
hl binary/hashlink/out.hl -cwd ./env -output ./out -std ../stdlib -ast yes main.alcl