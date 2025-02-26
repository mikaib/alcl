echo "Running tests..."
echo "Current directory: $PWD"

TEST_FILES=$(find ./Tests -type f)

echo "Test files:"

for file in $TEST_FILES do
    echo $file
done

./ALCL -cwd ./Tests -output ./Env/Out/Tests $TEST_FILES

echo "Tests complete."
