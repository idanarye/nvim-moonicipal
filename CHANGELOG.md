# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.3.0](https://github.com/idanarye/nvim-moonicipal/compare/v0.2.0...v0.3.0) (2024-10-10)


### Features

* `defer_to_coroutine` display error using `vim.notify` ([aca9e3c](https://github.com/idanarye/nvim-moonicipal/commit/aca9e3cc3f6b4b0eae9a1b3f5a2ba04ba74abb83))
* Add `moonicipal.import` as a new way to import libraries ([081af03](https://github.com/idanarye/nvim-moonicipal/commit/081af035f2e4b3966a7a269c5b2537aee30d7498))
* Add namespacing support for `moonicipal.include` ([947384c](https://github.com/idanarye/nvim-moonicipal/commit/947384c48194e878c68a94757b514ac1051d4184))


### Bug Fixes

* Don't use `tbl_add_reverse_lookup` (will be deprecated in Neovim 0.10) ([a012961](https://github.com/idanarye/nvim-moonicipal/commit/a012961c026b019c158d11af157659900c203e0e))
* Make `fix_echo` use `&lt;Cmd&gt;` instead of trying to guess the mode and always run into edge cases ([5cdc596](https://github.com/idanarye/nvim-moonicipal/commit/5cdc5963ad9f4810261b8862518eb806750e213e))
* Mark the `format` option of `cached_choice` as optional ([8b667f8](https://github.com/idanarye/nvim-moonicipal/commit/8b667f85790b8d3b5932ea3f2ef471d84caea46c))
* Namespaces now support `_` and `-` ([fe23860](https://github.com/idanarye/nvim-moonicipal/commit/fe23860261da72818bf1e4493283f30b8730cbf9))

## [0.2.0](https://github.com/idanarye/nvim-moonicipal/compare/v0.1.1...v0.2.0) (2023-11-01)


### Features

* Support `moonicipal.fix_echo` in the remaining modes (`'c'`, `'r'` and `'R'`) ([b0d7a2b](https://github.com/idanarye/nvim-moonicipal/commit/b0d7a2bcab35b7aaa10952e6f00ea1be11deb5de))
* Task libraries (`moonicipal.tasks_lib` and `moonicipal.merge_libs`) ([ba42cdb](https://github.com/idanarye/nvim-moonicipal/commit/ba42cdb9b52874843af8541983363d8be6808577))


### Bug Fixes

* Make `moonicipal.tasks_file` also be a table so that it can have methods registered on it ([b36e868](https://github.com/idanarye/nvim-moonicipal/commit/b36e8683a9da5674e160ba1fa67c9dc82c24273e))
* Track tasks to their source file with `:MCedit` and friends ([1eab038](https://github.com/idanarye/nvim-moonicipal/commit/1eab038b7ebeffe522f0eccad0106b84ccb7f9d7))

## [0.1.1](https://github.com/idanarye/nvim-moonicipal/compare/v0.1.0...v0.1.1) (2023-02-09)


### Bug Fixes

* `moonicipal.fix_echo()` after fzf-lua selection ([#1](https://github.com/idanarye/nvim-moonicipal/issues/1)) ([18afd81](https://github.com/idanarye/nvim-moonicipal/commit/18afd818c008500575a9aec5cb78c81c8141e4c2))

## 0.1.0 - 2023-01-02
### Added
- Syntax for defining tasks.
- Task running commands with completion.
- Helpers for creating task files and tasks.
- Caching mechanism.
- Helpers for common caching usecases.
- Data cells mechanism.
