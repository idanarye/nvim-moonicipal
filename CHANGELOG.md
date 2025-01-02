# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.4.0](https://github.com/idanarye/nvim-moonicipal/compare/v0.3.0...v0.4.0) (2025-01-02)


### ⚠ BREAKING CHANGES

* Data-cell automatically turn on `fail_if_empty` if `default` is not set
* When data-cell is not set but have a default - return that default

### Features

* `cached_choice` preselect the cached choice. ([8b2e3cc](https://github.com/idanarye/nvim-moonicipal/commit/8b2e3cc0d2c11048e7c028193e105055b41da5f6))
* Add `fail_if_empty` option for `cached_data_cell` ([dbf0988](https://github.com/idanarye/nvim-moonicipal/commit/dbf09881e9cb956a9551c095dffeafe86c400fbc))
* Add `preselect` option to `moonicipal.select` ([91b464c](https://github.com/idanarye/nvim-moonicipal/commit/91b464c2cd5e33e572a9fe0a825fd0f2151c0877))
* Add `priority` to `moonicipal.select` (and to `cached_choice`) ([f4f20eb](https://github.com/idanarye/nvim-moonicipal/commit/f4f20ebcbc363433eff97de9b806d60a8212b941))
* Add `select_1` option to `cached_choice` ([c963b4d](https://github.com/idanarye/nvim-moonicipal/commit/c963b4d38f85ef434628e632c252d34d7787b84c))
* Add keymaps for creating and editing actions form the `:MC` UI ([ccc7321](https://github.com/idanarye/nvim-moonicipal/commit/ccc7321ac83dea9e44ad30637115f93e35c2cf26))
* Allow opening the `:MC` UI when there is no tasks file (to support adding the first task with `&lt;M-a&gt;`) ([f410371](https://github.com/idanarye/nvim-moonicipal/commit/f4103713ba67656d2ab02219a8cb2101997f6446))
* Better interaction selection UIs (fzf-lua and Telescope) ([fd7325e](https://github.com/idanarye/nvim-moonicipal/commit/fd7325e0e388bd305d1e735db126f8b24f471420))
  * Configurable via the `selection` parameter to `setup`.
  * Defaults to Neovim's builtin `vim.ui.select()` - users have to actively choose which selection UI they want.
  * Comes with [fzf-lua](https://github.com/ibhagwan/fzf-lua) integration: just set `selection = 'moonicipal.selection.fzf-lua',` in the `setup`.
  * Comes with [Telescope](https://github.com/nvim-telescope/telescope.nvim) integration: just set `selection = 'moonicipal.selection.telescope',` in the `setup`.
  * Support multiple selection.
  * Support previewers.
  * Support actions.



### Bug Fixes

* Better prompt formatting in `moonicipal.select` ([d85873e](https://github.com/idanarye/nvim-moonicipal/commit/d85873ef8c43f6845cf3367a04bec76c4494bdad))
* Data-cell automatically turn on `fail_if_empty` if `default` is not set ([468c9ee](https://github.com/idanarye/nvim-moonicipal/commit/468c9eeb6bf2d8e2eea192557c58a21d5cabea52))
* Invalidate a missing cached `cached_choice` choice even if it was not replaced by a different selection ([8da7111](https://github.com/idanarye/nvim-moonicipal/commit/8da7111c82060e517b00dc3c697a00b30f58647f))
* When data-cell is not set but have a default - return that default ([3c899db](https://github.com/idanarye/nvim-moonicipal/commit/3c899db085c3a6e8b7c4f0e6e6390cbacaa5622f))

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
