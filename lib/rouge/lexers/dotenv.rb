# frozen_string_literal: true

# Rouge lexer for dotenv (.env) environment variable files.
#
# Every construct recognised here is taken from the env.dev dotenv guide
# (https://env.dev/guides/dotenv): KEY=value assignments, `#` comments,
# double-quoted values (spaces, special characters, multiline and `${VAR}`
# expansion), single-quoted literal values, empty values and `${VAR}`
# expansion in unquoted values. See AGENTS.md for the design notes.
module Rouge
  module Lexers
    class Dotenv < RegexLexer
      title 'dotenv'
      desc 'dotenv (.env) environment variable files (env.dev/guides/dotenv)'
      tag 'dotenv'
      aliases 'env', '.env', 'environment'
      # `.env.test` also matches the PHP lexer's `*.test` (Drupal) pattern and
      # cannot be disambiguated by filename alone; see the project notes in
      # AGENTS.md. Passing the source to Rouge::Lexer.guess resolves it.
      filenames '.env', '.env.*', '*.env'
      mimetypes 'text/x-dotenv'

      # Boolean values, as used by feature flags in the documentation
      # (ENABLE_CACHE=true). Only recognised when they are the whole value.
      def self.constants
        @constants ||= Set.new %w(true false)
      end

      # A .env file is a sequence of KEY=value lines (uppercase keys by
      # convention, no whitespace around the `=`), blank lines and `#`
      # comments. Require the first few meaningful lines to look like that.
      def self.detect?(text)
        lines = text.lines.map(&:strip).reject { |l| l.empty? || l.start_with?('#') }.first(5)
        return false if lines.empty?

        lines.all? { |l| l.match?(/\A[A-Z][A-Z0-9_]*=/) }
      end

      # Lookahead: nothing but optional blanks and an optional inline comment
      # remain on the line, so the token just matched is the whole value.
      END_OF_VALUE = /(?=[ \t]*(?:#.*)?$)/.freeze

      state :whitespace do
        rule %r/\s+/, Text::Whitespace
      end

      state :comment do
        rule %r/#.*/, Comment::Single
      end

      state :root do
        mixin :whitespace
        mixin :comment

        # KEY=value. Whitespace around `=` is a documented pitfall that breaks
        # most parsers; it is still tokenised so a stray space does not turn
        # the whole line into an error.
        rule %r/([A-Za-z_][A-Za-z0-9_]*)([ \t]*)(=)/ do
          groups Name::Variable, Text::Whitespace, Operator
          push :value
        end
      end

      # Everything after `=` up to the end of the line.
      state :value do
        rule %r/\n/, Text::Whitespace, :pop!
        rule %r/[ \t]+/, Text::Whitespace

        # Inline comment. Only reachable at a token boundary, i.e. right after
        # `=` or after whitespace; a `#` glued to an unquoted value (the
        # documented URL=https://x.com#anchor pitfall) stays part of the value.
        mixin :comment

        rule %r/"/, Str::Double, :double_string
        rule %r/'/, Str::Single, :single_string

        mixin :interpolation

        rule %r/\d+#{END_OF_VALUE}/, Num::Integer

        rule %r/[A-Za-z]+#{END_OF_VALUE}/ do |m|
          if self.class.constants.include?(m[0])
            token Keyword::Constant
          else
            token Str
          end
        end

        # Unquoted value text, stopping at whitespace and at `${` expansions
        rule %r/[^\s$]+/, Str
        rule %r/\$/, Str
      end

      # Double quotes allow spaces, special characters, multiline values and
      # `${VAR}` expansion.
      state :double_string do
        rule %r/"/, Str::Double, :pop!
        rule %r/\\./m, Str::Escape
        mixin :interpolation
        rule %r/[^"\\$]+/m, Str::Double
        rule %r/\$/, Str::Double
      end

      # Single quotes are literal: no escapes, no interpolation.
      state :single_string do
        rule %r/'/, Str::Single, :pop!
        rule %r/[^']+/m, Str::Single
      end

      state :interpolation do
        rule %r/\$\{/, Str::Interpol, :curly
      end

      state :curly do
        rule %r/\}/, Str::Interpol, :pop!
        rule %r/[A-Za-z_][A-Za-z0-9_]*/, Name::Variable
        # An unterminated `${` ends at the line break; leave the newline to the
        # enclosing state so it can close the value as well.
        rule(/(?=\n)/) { pop! }
        rule %r/[ \t]+/, Text::Whitespace
      end
    end
  end
end
