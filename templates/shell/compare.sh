#!/bin/bash

make exception
make $1
start=1

if [[ $# -eq 2 ]]; then
    start=$2
fi

for (( i = $start; i < 200000; i++ )); do
    for (( ; i % 100; i++ )); do
        a=$(./exception $i)
        b=$(./$1 $i)
        if [[ "$a" != "$b" ]]; then
            echo "ERR <== $i: $b -> $a"
            exit
        fi
    done
    echo "$(($i-1)): $b -> $a"
done
