.PHONY: all
all: format-check lint

.PHONY: format-check
format-check:
	stylua . --check

.PHONY: format
format:
	stylua .

.PHONY: lint
lint:
	luacheck -q .

.PHONY: test-smart-files
test-smart-files:
	NVIM_APPNAME=nvim nvim --headless '+packadd plenary.nvim' '+PlenaryBustedFile tests/smart_files_spec.lua'
