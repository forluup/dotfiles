# Rust/cargo toolchain on PATH.
#
# This lived in ~/.config/zsh/.zshenv before HyDE, which syncs that file and
# replaced it with a conf.d loader. conf.d is HyDE's documented extension point
# and is not overwritten on update, so the line lives here now.
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
