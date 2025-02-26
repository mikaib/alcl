echo "Running tests..."
echo "Current directory: $PWD"

cd ./Tests
TEST_FILES=$(find . -type f)
cd ..

echo "Test files:"

for file in $TEST_FILES
do
    echo "$file"
done

./ALCL -cwd ./Tests -output ./Env/Out/Tests $TEST_FILES

echo "Tests complete."
