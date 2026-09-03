# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Commands

```sh
bundle config set --local path vendor/bundle && bundle install  # Install dependencies
bundle exec rake        # Run the test suite (default task)
bundle exec rake server # Start visual preview server at http://localhost:9292
ruby preview.rb         # Terminal preview using Github theme
DEBUG=1 ruby preview.rb # Print each token and its type
```

To check for error tokens via the preview server:

```sh
curl -s http://localhost:9292 | grep 'class="err"'
```

## Architecture

This is a Rouge lexer plugin gem for dotenv (.env) environment variable files. Rouge is the
default syntax highlighter used by Jekyll/GitHub Pages.

**Key files:**

- [lib/rouge/lexers/dotenv.rb](lib/rouge/lexers/dotenv.rb) — The lexer implementation (`Rouge::Lexers::Dotenv < RegexLexer`)
- [lib/rouge/lexer/dotenv.rb](lib/rouge/lexer/dotenv.rb) — Entry point that `require`s the lexer; this is what consumers load
- [spec/rouge_lexer_dotenv_spec.rb](spec/rouge_lexer_dotenv_spec.rb) — Minitest test suite
- [spec/demos/dotenv](spec/demos/dotenv) — Short demo snippet used in tests and Rouge's demo pages
- [spec/visual/samples/dotenv](spec/visual/samples/dotenv) — Comprehensive sample used for visual testing and error-token checks

**Lexer structure:** The lexer uses a class-level `Set` cache for the boolean
constants. The `:root` state matches comments and `KEY=` assignments and pushes
a `:value` state for the rest of the line; a whole-value `[A-Za-z]+` rule does a
set-membership lookup to assign `Keyword::Constant` or plain `Str`. Sub-states
handle double-quoted strings, single-quoted strings and `${VAR}` expansion.

## Design notes

**Line-oriented states.** A .env file has no nesting beyond a single
`KEY=value` line, so `:root` only knows about whitespace, `#` comments and the
`KEY=` prefix. Matching `KEY=` pushes `:value`, which owns everything up to the
newline and pops on it. Quoted strings are sub-states of `:value` so that a
closing quote returns to `:value`, letting a trailing inline comment be
tokenised and the newline close the line. Double-quoted strings match newlines
(`/m`) because the guide says some parsers support multiline values in double
quotes; the newline that finally closes the line is the one after the closing
quote.

**Whole-value literals.** `PORT=3000` and `ENABLE_CACHE=true` are the
documented examples of numeric and boolean values. They are only recognised
when the literal is the entire unquoted value (`END_OF_VALUE` lookahead:
optional blanks and an optional inline comment, then end of line). Anything
else unquoted, such as `localhost`, `sk_test_abc123` or a URL, is `Str`. There
is no `Num::Float` rule because the guide shows no float values; the `\d+\.\d+`
that appears in it is a regex inside a single-quoted string.

**Token assignments that depart from the template table:**

- Keys are `Name::Variable` (the guide calls them environment variables) and
  the `=` is `Operator` (assignment). Rouge's INI lexer uses `Name::Property`
  and `Punctuation`; `Name::Variable` was chosen because the same name is what
  `${VAR}` expansion refers to, so both ends of a reference get the same token.
- `${` and `}` are `Str::Interpol` with the name inside as `Name::Variable`,
  following Rouge's shell lexer rather than the table's `Name::Function` or
  `Name::Variable::Magic`. Expansion is recognised in unquoted values and in
  double-quoted strings, never in single-quoted strings (the guide: single
  quotes mean "no interpolation").
- Unquoted values are `Str` (the INI lexer convention), not `Name`, because a
  .env value is data, not an identifier.
- `\.` inside double quotes is `Str::Escape` (JSON/INI lexer convention). The
  guide only says double quotes allow "special characters"; the escape rule is
  there so an escaped `\"` does not end the string early.
- Only `true` and `false` are constants. `true` appears in the guide's
  feature-flag example; `false` is its counterpart and the only other value a
  feature flag can take. Uppercase `TRUE`/`FALSE` are not recognised.

**Inline comments.** The guide says `KEY=value # comment` is supported by some
parsers but not all, and that an unquoted `URL=https://x.com#anchor` gets
truncated by many parsers. The lexer treats `#` as a comment only at a token
boundary (right after `=` or after whitespace); a `#` glued to unquoted text is
kept as part of the value, since highlighting half a URL as a comment would be
more surprising than not. `#` inside quotes is always string content.

**Deliberate limits.** Nothing outside the guide is tokenised: no `export`
prefix, no `$VAR` without braces, no `${VAR:-default}` operators, no backtick
strings. An unrecognised construct in `:root` (for example a bare word without
`=`) produces an `Error` token on purpose so it shows up in the preview.
Inside `${...}` only a name and blanks are accepted; an unterminated `${` pops
at the newline via a zero-width lookahead rule so the enclosing `:value` state
still sees the newline and closes the line. Whitespace around `=` is a
documented pitfall ("will break most parsers") but is tokenised as
`Name::Variable`, `Text::Whitespace`, `Operator` so a stray space does not turn
the line into an error.

**Detection.** `detect?` takes the first five non-blank, non-comment lines and
requires every one to start with an uppercase `KEY=` with no space before the
`=`. That is strict enough to reject shell scripts (shebang), JSON and INI
sections, and loose enough to accept a typical `.env`. Filename patterns cover
`.env`, the per-environment `.env.development` / `.env.production` /
`.env.test` / `.env.local` / `.env.example` files named in the guide, and
`*.env`.

## .env references

Use *ONLY* official documentation, *NOT* from memory, training, or inference.

### Documentation

**MANDATORY: Before writing or modifying the lexer, you MUST fetch and read every
URL in this list.** This is not background reading — it is a required prerequisite
step. Fetch each page, extract the keywords or function names, and verify them
against the lexer before declaring any work complete.

https://env.dev/guides/dotenv

## Rouge references

- Lexer development guide: <https://github.com/rouge-ruby/rouge/blob/main/docs/LexerDevelopment.md>
- Existing lexers for reference: <https://github.com/rouge-ruby/rouge/tree/main/lib/rouge/lexers>
- JSON lexer (simple example): <https://github.com/rouge-ruby/rouge/blob/main/lib/rouge/lexers/json.rb>
- SQL lexer (keyword-heavy analog): <https://github.com/rouge-ruby/rouge/blob/main/lib/rouge/lexers/sql.rb>
- Token types: <https://github.com/rouge-ruby/rouge/blob/main/lib/rouge/token.rb>

## Verification workflow (MANDATORY — do this BEFORE adding anything)

Before writing or modifying the lexer, fetch **every URL in the documentation
list** above. Do not begin implementation until all pages have been read.

Before adding ANY individual keyword, function, or syntax element:

1. **Fetch the relevant documentation page** using the WebFetch tool or curl.
2. **Extract and confirm** the element exists in the fetched content. Do not rely
   on training data, memory, or assumptions about what "should" exist.
3. **Only add** elements that appear in the fetched content. **Only remove**
   elements confirmed absent.

### What NOT to do

- **Do NOT add keywords or syntax from training data or memory.** Every addition
  must be traced to a specific URL from the reference list in this file.
- **Do NOT use preview/beta features** unless explicitly asked. Only add GA
  (generally available) features.
- **Do NOT fabricate or modify reference URLs.** Use ONLY the exact URLs listed
  in this file. If a URL doesn't work, say so — do not guess an alternative.
- **Do NOT assume a function exists because a similar one does.**

### Self-verification

After making changes, verify correctness by **re-fetching the source documentation**
and confirming every added element appears in the fetched HTML. Do not verify by
re-reading your own changes.

### Constraints (applies to all work)

- **No hallucinated syntax.** Every keyword, function, operator, and language
  construct in the lexer must come from the official documentation listed above.
- **Follow Rouge conventions exactly.** Study existing lexers (especially JSON and
  SQL) for patterns. Don't invent novel approaches.
- **The Error token count is the ground truth.** The visual preview server is the
  authoritative test. `bundle exec rake` passing is necessary but not sufficient —
  you must also have zero `class="err"` spans.
- **Iterate until clean.** Do not declare the task complete until both
  `bundle exec rake` passes AND the Error token count is zero for both demo and
  visual sample.
- **Update the visual sample** (`spec/visual/samples/dotenv`)
  whenever new tokens are added to the lexer, so every token type has coverage.

The markdownlint rules in [.markdownlint.json](.markdownlint.json) are shared by
the VS Code extension and the CI lint job. `MD024` is `siblings_only: true`,
allowing repeated heading text under different parent headings (e.g. `### Added`
appearing under multiple version sections in the changelog); line length is off,
tabs are allowed in code blocks, and bare URLs are allowed.

## Continuous integration and releases

GitHub Actions workflows live in [.github/workflows/](.github/workflows/):

- [test.yml](.github/workflows/test.yml) runs `bundle exec rake` on every Ruby
  from 3.0 to 3.4 against Rouge `~> 3.4`, `~> 4.0` and `>= 5.0`, then fails if
  the demo or visual sample produce any error tokens. The Gemfile reads
  `ROUGE_VERSION` to pin Rouge; unset locally, it installs the newest.
- [markdownlint.yml](.github/workflows/markdownlint.yml) lints every Markdown
  file with the rules in [.markdownlint.json](.markdownlint.json).
- [release.yml](.github/workflows/release.yml) runs on tags matching `v*`. It
  checks the tag against the gemspec version, runs the tests, publishes to
  RubyGems with trusted publishing (OIDC, no API key secret) and creates a
  GitHub release with the built gem attached. The repository and workflow must
  be registered once as a trusted publisher on rubygems.org.
- [dependabot.yml](.github/dependabot.yml) keeps gems and action versions
  current with weekly pull requests.

To release: bump `s.version` in the gemspec, add the version section to the
changelog, commit, then `git tag vX.Y.Z && git push --tags`.

## Project notes

- The env.dev guide (fetched 2026-09-03) is the only documentation source. It
  is a general guide, not a spec, and says so itself: "The dotenv format has no
  formal spec" and behaviour "differs between dotenv, dotenvx, Docker, and
  shell sourcing". It links to a separate ".env file syntax reference" page
  for per-parser rules, but that page is not in the reference list and was
  not used. Do not add constructs from it, or from any parser's README,
  without first adding the URL to the Documentation list above.
- Constructs the guide does **not** describe, and that are therefore absent
  from the lexer on purpose: the `export` prefix, `$VAR` expansion without
  braces, `${VAR:-default}` style operators, backtick strings, float values,
  uppercase `TRUE`/`FALSE`, and `\n`-style escapes as a documented feature.
- `false` is the one value not literally printed in the guide; it is included
  as the counterpart of the documented `ENABLE_CACHE=true` feature flag.
- The lexer was tested locally against Rouge 3.4.0, 4.7.0 and 5.1.0 on Ruby
  3.3. `Str::Interpol`, `Name::Variable` and the zero-width `(?=\n)` rule all
  work on Rouge 3.4.0. Neither `dotenv` nor `env` was registered as a tag or
  alias by any of those Rouge versions.
- Rouge's filename guesser matches `.env.*` and `*.env` with `File.fnmatch`,
  so `.env.example` and `production.env` resolve to this lexer; a bare `.env`
  needs its own pattern because `.env.*` does not match it.
- `.env.test` is ambiguous by filename alone: Rouge's PHP lexer registers
  `*.test` for Drupal, which ties with `.env.*` on wildcard count.
  `Rouge::Lexer.guess(filename: '.env.test')` therefore raises
  `Rouge::Guesser::Ambiguous`. Adding a literal `.env.test` pattern does not
  help, because Rouge's glob guesser scores a lexer by its *worst* matching
  pattern (`GlobMapping#filter` takes the `.min` over the patterns that
  match), so `.env.*` still counts. Passing the file contents as well
  (`guess(filename: ..., source: ...)`) lets `detect?` break the tie, which is
  what the spec asserts.

## Changelog

The changelog ([CHANGELOG.md](CHANGELOG.md)) follows the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). When updating the
changelog:

- Use `## [version] - YYYY-MM-DD` for release headings
- Use `### Added`, `### Changed`, `### Removed` as second-level section headings
- Use `#### Category name` as optional third-level headings within a section
- Ensure blank lines surround all headings to satisfy markdownlint
