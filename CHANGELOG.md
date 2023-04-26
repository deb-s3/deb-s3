# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.11.7] - 2023-04-26
### Fixed
* Filenames with "+" get converted to spaces #11 

## [0.11.6] - 2022-11-06
### Changed
* changed `--sign` param for multiple signing keys to be repeatable

## [0.11.5] - 2022-11-05
### Added
* added support for multiple signing keys (to allow keyring rotation)
### Fixed
* fixed ERB.new deprecations (#26)
### Changed
* bump ruby to 2.7.0

## [0.11.4] - 2022-07-08
### Added
* added support for zstd compressed control files (requires zstd support in `dpkg-dev`)

[0.11.4]: https://github.com/deb-s3/deb-s3/compare/0.11.3...0.11.4

## [0.11.3] - 2021-04-08
### Changed
* bump aws sdk components

[0.11.3]: https://github.com/deb-s3/deb-s3/compare/0.11.2...0.11.3

## [0.11.2] - 2020-09-08
### Changed
* [#2](https://github.com/deb-s3/deb-s3/pull/2): bump aws sdk to v3

[0.11.2]: https://github.com/deb-s3/deb-s3/compare/0.11.1...0.11.2
