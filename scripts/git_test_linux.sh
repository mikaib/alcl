echo "Running tests..."
echo "Current directory: $PWD"

cd ./Tests
TEST_FILES=$(find . -type f | sed 's|^\./||')
cd ..

echo "Test files:"
for file in $TEST_FILES
do
    echo "- $file"
done

./ALCL -verbose yes -cwd ./tests -compile cmake -std ../stdlib -output ../env/out/tests $TEST_FILES
echo "Tests generated!"
