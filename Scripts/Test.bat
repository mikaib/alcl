@echo off
call Scripts/Env
haxe build.hxml
hl Binary/Hashlink/out.hl -verbose -cwd ./Tests -compile cmake -output ../Env/Out/Tests -std ../Stdlib test_ternary.alcl test_for.alcl test_math.alcl test_while.alcl test_comparisons.alcl tests.alcl