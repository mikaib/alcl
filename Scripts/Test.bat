@echo off
call Scripts/Env
haxe build.hxml
hl Binary/Hashlink/out.hl -cwd ./Tests -output ../Env/Out/Tests -std C:/projects/ALCL/Stdlib test_math.alcl test_while.alcl test_comparisons.alcl tests.alcl