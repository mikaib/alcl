@echo off
call Scripts/Env
haxe build.hxml
hl Binary/Hashlink/out.hl -cwd ./Tests -output ../Env/Out/Tests test_math.alcl test_while.alcl test_comparisons.alcl tests.alcl