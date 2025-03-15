echo "Running tests..."
echo "Current directory: $PWD"

cd ./tests
TEST_FILES=$(find . -type f | sed 's|^\./||')
cd ..

echo "Test files:"
for file in $TEST_FILES
do
    echo "- $file"
done

./ALCL -verbose -compile cmake -output ./env/out/tests $TEST_FILES
echo "Tests generated!"
