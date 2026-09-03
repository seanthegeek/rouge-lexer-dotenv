# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-03

### Added

- Initial release of the `rouge-lexer-dotenv` gem
- `Rouge::Lexers::Dotenv` lexer with tag `dotenv`, aliases `env`, `.env` and
  `environment`, filename patterns `.env`, `.env.*` and `*.env`, and MIME type
  `text/x-dotenv`
- Auto-detection heuristics based on common .env patterns (leading
  `KEY=value` lines with uppercase keys)
- Token classification for keys, the `=` operator, unquoted values, integer
  and boolean values, double-quoted values (including multiline values and
  escape sequences), single-quoted literal values, `${VAR}` expansion, and
  whole-line and inline `#` comments

[0.1.0]: https://github.com/seanthegeek/rouge-lexer-dotenv/releases/tag/v0.1.0
