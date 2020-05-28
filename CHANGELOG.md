# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2020-05-28

The package was removed from its previous organisation. In order to keep the
source code public for a package that's still available on Hex, the project
has been forked and is now hosted under the original author's GitHub namespace.
This is in accordance with its Apache license.

Most of the source code was recoverable from Hex, but unfortunately the Git
history, the tests, and Travis CI configuration were not recoverable as they
were excluded from the published package.

## [1.0.0] - 2019-04-30

### Added
- Support for time filtering
  - `between/3`
  - `days_ago/2`
  - `hours_ago/2`
  - `minutes_ago/2`
  - `within/2`
- Support for searching a specific message field
  - `for/3`
  - `and_for/3`
  - `and_not/3` 
  - `not_for/3`
  - `or_for/3`
- Support for showing more message fields
  - `show_fields/2`

### Changed
- `url/1` can now return an error tuple
- More idiomatic function names for searching
  - `by/2` => `for/2`
  - `and_by/2` => `and_for/2`
  - `not_by/2` => `not_for/2`
  - `or_by/2` => `or_for/2`

## [0.1.0] - 2019-03-18

First public release.

### Added
- Support for basic queries
  - `new/1`
  - `by/2`
  - `and_by/2`
  - `and_not/2`
  - `not_by/2`
  - `or_by/2`
  - `url/1`

[Unreleased]: https://github.com/dideler/graylog_search/compare/v1.0.1...HEAD
[1.0.0]: https://github.com/dideler/graylog_search/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/dideler/graylog_search/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/dideler/graylog_search/compare/e0f9363...v0.1.0