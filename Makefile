include spec/.shared/neovim-plugin.mk

export REQUIREALL_IGNORE_MODULES:=waitevent%.script

spec/.shared/neovim-plugin.mk:
	git clone https://github.com/notomo/workflow.git --depth 1 spec/.shared
