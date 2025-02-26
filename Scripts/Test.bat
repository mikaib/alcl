@echo off
call Scripts/Env
haxe build.hxml
hl Binary/Hashlink/out.hl -cwd ./Tests -compile cmake -output ../Env/Out/Tests -std ../Stdlib test_math.alcl test_while.alcl test_comparisons.alcl tests.alcl