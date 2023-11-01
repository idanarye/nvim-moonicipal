# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

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
