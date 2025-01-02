#!/bin/bash

for testfile in tests/*_spec.lua; do
    nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory $testfile {minimal_init = 'tests/minimal_init.lua'}"
done
