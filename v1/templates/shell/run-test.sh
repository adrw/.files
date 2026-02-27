#!/usr/bin/env bash

# assumes this is placed in dir and following test structure
# dir / tests / {testID} / {testName}.in
# dir / tests / {testID} / {testName}.expect

default="a4q1"

div="***************************************************************************"
function status {
  echo ""
  echo "[ ${1} ] ${div:${#1}}"
}

vid="---------------------------------------------------------------------------"
function update {
  echo ""
  echo "[ ${1} ] ${vid:${#1}}"
}

function show_help {
  echo "./run-test.sh { } {file prefix ie. a2q1}"
  echo "-q    {no continue prompts}"
  exit 0
}

QUIET=false
while getopts "h?:qd" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    d)  DIFF=true
        echo "Option Registered: show diff output"
        ;;
    q)  QUIET=true
        echo "Option Registered: quiet"
        ;;
    esac
done
shift $((OPTIND-1))

test_exec=$1
if [ -z "$1" ]; then
  test_exec=$default
fi
rm ${test_exec}.exec
make $test_exec
dir=tests/$test_exec

passed=0
failed=0

for filename in $dir/*.in; do
  filename=$(basename "$filename" .in)
  # ruler="0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 "
  in=$(cat $dir/${filename}.in)
  expect=$(cat $dir/${filename}.expect)
  out=$(./${test_exec}.exec < $dir/${filename}.in)
  result=$(diff -b <(echo "$expect") <(echo "$out"))
  status "Test :: $dir/${filename}.in"
  if [[ "$QUIET" != true ]]; then
    update "Input |>"
    echo "$in"
  fi
  update "<| Output"
  echo "$out"
  if [ -z "$result" ]; then
    passed=$(($passed+1))
    update "✅  Pass :: $dir/${filename}.in"
  else
    failed=$(($failed+1))
    update "❌  Fail :: $dir/${filename}.in"
    if [[ "$DIFF" == true ]]; then echo "$result"; fi
  fi
  if [[ "$QUIET" == false ]]; then
    read -p "Next test? [y/n/enter]" -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Nn]$ ]]
    then
      break # do dangerous stuff
    fi
  fi
done
if [[ $failed == 0 ]]; then
  status "🍺  Result :: $passed / $(($passed + $failed))"
else
  status "💨  Result :: $passed / $(($passed + $failed))"
fi
