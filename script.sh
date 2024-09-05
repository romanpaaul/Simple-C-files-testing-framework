#!/bin/bash

identify_c_files() {
    find "$1" -type f -name "*.c"
}

compile_c_file() {
    source_file="$1"
    output_folder="$2"
    
    file_name=$(basename "$source_file")
    executable_name="${file_name%.*}"
    output_path="$output_folder/$executable_name"

    gcc "$source_file" -o "$output_path"

    if [ $? -eq 0 ]; then
        echo "$output_path"
    else
        echo "Compilation error for $source_file"
        return 1
    fi
}

run_executable() {
    executable_path="$1"
    input_file="$2"
    
    if [ -n "$input_file" ]; then
        result=$(cat "$input_file" | "$executable_path")
    else
        result=$("$executable_path")
    fi

    echo "$result"
}

get_interactive_input() {
    input_file="$1"
    echo "Enter interactive input (press Enter on a new line to finish, Ctrl+D to end):"
    cat > "$input_file"
}

test_executable() {
    executable_path="$1"
    expected_exit_code="$2"
    expected_output_file="$3"
    input_file="$4"

    actual_exit_code=$(run_executable "$executable_path" "$input_file" | head -n 1)
    actual_output=$(run_executable "$executable_path" "$input_file" | tail -n +2)

    if [ "$actual_exit_code" -eq "$expected_exit_code" ] && [ "$actual_output" == "$expected_output_file" ]; then
        echo "Test passed: $actual_exit_code, $actual_output"
        return 0
    else
        echo "Test failed: Exit code - Expected: $expected_exit_code, Actual: $actual_exit_code; Output - Expected: $expected_output_file, Actual: $actual_output"
        return 1
    fi
}

count_successful_tests() {
    source_folder="$1"
    output_folder="$2"
    test_folder="$3"
    interactive_folder="$4"

    successful_tests=0
    failed_tests=0

    for source_file in "$source_folder"/*.c; do
        executable_path=$(compile_c_file "$source_file" "$output_folder")

        if [ $? -eq 0 ]; then
            test_file="$test_folder/$(basename "$source_file" .c).txt"
            input_file="$interactive_folder/$(basename "$source_file" .c)_input.txt"

            if grep -q "# INTERACTIVE" "$test_file"; then
                get_interactive_input "$input_file"
            fi

            if test_executable "$executable_path" 0 "$(cat "$test_file")" "$input_file"; then
                ((successful_tests++))
            else
                ((failed_tests++))
            fi
        else
            ((failed_tests++))
        fi
    done

    echo "Number of successful tests: $successful_tests"
    echo "Number of failed tests: $failed_tests"

    total_tests=$((successful_tests + failed_tests))
    success_percentage=$((100 * successful_tests / total_tests))

    echo "Success/Failure Ratio: $success_percentage% / $((100 - success_percentage))%"
}

main() {
    if [ $# -ne 2 ]; then
        echo "Usage: $0 <source_folder> <output_folder>"
        exit 1
    fi

    source_folder="$1"
    output_folder="$2"
    test_folder="Tests"
    interactive_folder="InteractiveInput"

    [ -d "$source_folder" ] || mkdir -p "$source_folder"
    [ -d "$interactive_folder" ] || mkdir -p "$interactive_folder"

    if [ ! -d "$source_folder" ]; then
        echo "Source folder not found or couldn't be created."
        exit 1
    fi

    if [ ! "$(identify_c_files "$source_folder")" ]; then
        echo "No C files found for testing in $source_folder."
        exit 1
    fi

    [ -d "$output_folder" ] || mkdir -p "$output_folder"

    count_successful_tests "$source_folder" "$output_folder" "$test_folder" "$interactive_folder"
}

main "$@"
