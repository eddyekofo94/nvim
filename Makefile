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

.PHONY: test-lazy-loading
test-lazy-loading:
	NVIM_APPNAME=nvim nvim --headless '+packadd plenary.nvim' '+PlenaryBustedFile tests/lazy_loading_spec.lua'

.PHONY: test-copilot-lifecycle
test-copilot-lifecycle:
	sh tools/test_copilot_lifecycle.sh

.PHONY: test-cwd-files
test-cwd-files:
	NVIM_APPNAME=nvim nvim --headless '+packadd plenary.nvim' '+PlenaryBustedFile tests/cwd_files_spec.lua'
