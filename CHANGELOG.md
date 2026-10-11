# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Bumped `ameba` dev dependency from `~> 1.6.0` to `~> 1.7.0` and fixed the
  resulting lint violations.
- Standardized the CI workflow into separate `lint` and `test` jobs using
  `actions/checkout@v4` and pinned Crystal version, with shard caching.
- Added `shards install` step to the GitHub Pages docs workflow.

### Added

- Added `fmtcheck`, `version`, and `tag` targets to the `Makefile`.
