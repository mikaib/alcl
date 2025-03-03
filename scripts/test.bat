@echo off
call Scripts/Env
haxe build.hxml
hl binary/hashlink/out.hl -verbose -cwd ./tests -compile cmake -output ../env/out/tests -std ../stdlib test_ternary.alcl test_for.alcl test_math.alcl test_while.alcl test_comparisons.alcl tests.alcl