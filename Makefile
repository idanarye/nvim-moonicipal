.PHONY: docs test

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"


docs:
	mkdir -p doc
	lemmy-help --prefix-func lua/moonicipal/{init,_just_for_documentation,settings,Task,CachedChoice}.lua | tee doc/moonicipal.txt
