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

./ALCL -cwd ./Tests -compile cmake -std ../Stdlib -output ../Env/Out/Tests $TEST_FILES
echo "Tests generated!"
