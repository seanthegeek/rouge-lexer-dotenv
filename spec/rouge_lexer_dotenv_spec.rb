# frozen_string_literal: true

require 'minitest/autorun'
require 'rouge'
require 'rouge/lexer/dotenv'

class RougeLexerDotenvTest < Minitest::Test
  def setup
    @lexer = Rouge::Lexers::Dotenv.new
  end

  def test_finds_by_tag
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.find('dotenv')
  end

  def test_finds_by_alias_env
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.find('env')
  end

  def test_finds_by_alias_dot_env
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.find('.env')
  end

  def test_finds_by_alias_environment
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.find('environment')
  end

  def test_guesses_by_filename
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: '.env')
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: '.env.example')
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: '.env.development')
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: '.env.production')
    # Rouge's PHP lexer registers `*.test` (Drupal), so `.env.test` is
    # ambiguous by filename alone; the source heuristic breaks the tie.
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: '.env.test', source: load_demo)
    assert_includes Rouge::Lexer.guesses(filename: '.env.test'), Rouge::Lexers::Dotenv
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: '.env.local')
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(filename: 'production.env')
  end

  def test_guesses_by_mimetype
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(mimetype: 'text/x-dotenv')
  end

  def test_detects_by_source
    source = "# App\nNODE_ENV=development\nPORT=3000\n"
    assert_equal Rouge::Lexers::Dotenv, Rouge::Lexer.guess(source: source)
  end

  def test_does_not_detect_unrelated_source
    refute Rouge::Lexers::Dotenv.detect?(Rouge::TextAnalyzer.new("#!/bin/sh\necho hi\n"))
    refute Rouge::Lexers::Dotenv.detect?(Rouge::TextAnalyzer.new("{\n  \"a\": 1\n}\n"))
    refute Rouge::Lexers::Dotenv.detect?(Rouge::TextAnalyzer.new("# only a comment\n"))
  end

  def test_assignment_tokens
    assert_equal [
      [Rouge::Token::Tokens::Name::Variable, 'DATABASE_HOST'],
      [Rouge::Token::Tokens::Operator, '='],
      [Rouge::Token::Tokens::Str, 'localhost'],
      [Rouge::Token::Tokens::Text::Whitespace, "\n"]
    ], tokens("DATABASE_HOST=localhost\n")
  end

  def test_integer_and_boolean_values
    assert_includes tokens("PORT=3000\n"), [Rouge::Token::Tokens::Num::Integer, '3000']
    assert_includes tokens("ENABLE_CACHE=true\n"), [Rouge::Token::Tokens::Keyword::Constant, 'true']
    assert_includes tokens("TOKEN=abc123\n"), [Rouge::Token::Tokens::Str, 'abc123']
  end

  def test_comments
    assert_equal [[Rouge::Token::Tokens::Comment::Single, '# Database config'],
                  [Rouge::Token::Tokens::Text::Whitespace, "\n"]],
                 tokens("# Database config\n")
    assert_includes tokens("KEY=value # note\n"), [Rouge::Token::Tokens::Comment::Single, '# note']
    assert_includes tokens("URL=https://x.com#anchor\n"), [Rouge::Token::Tokens::Str, 'https://x.com#anchor']
  end

  def test_empty_values
    assert_equal [[Rouge::Token::Tokens::Name::Variable, 'DB_PASSWORD'],
                  [Rouge::Token::Tokens::Operator, '='],
                  [Rouge::Token::Tokens::Text::Whitespace, "\n"]],
                 tokens("DB_PASSWORD=\n")
    assert_includes tokens("DB_NAME=\"\"\n"), [Rouge::Token::Tokens::Str::Double, '""']
  end

  def test_quoted_values
    assert_includes tokens("GREETING=\"Hello, World!\"\n"), [Rouge::Token::Tokens::Str::Double, '"Hello, World!"']
    assert_includes tokens("REGEX='\\d+\\.\\d+'\n"), [Rouge::Token::Tokens::Str::Single, "'\\d+\\.\\d+'"]
    refute_includes tokens("REGEX='${NOT_EXPANDED}'\n").map(&:first), Rouge::Token::Tokens::Str::Interpol
  end

  def test_multiline_double_quoted_value
    source = "PRIVATE_KEY=\"-----BEGIN RSA KEY-----\nMIIBogIBAAJBALRi...\n-----END RSA KEY-----\"\nNEXT=1\n"
    toks = tokens(source)
    assert_includes toks, [Rouge::Token::Tokens::Name::Variable, 'NEXT']
    assert_includes toks, [Rouge::Token::Tokens::Num::Integer, '1']
  end

  def test_variable_expansion
    toks = tokens("FULL_URL=${BASE_URL}/v1/users\n")
    assert_includes toks, [Rouge::Token::Tokens::Str::Interpol, '${']
    assert_includes toks, [Rouge::Token::Tokens::Name::Variable, 'BASE_URL']
    assert_includes toks, [Rouge::Token::Tokens::Str::Interpol, '}']
    assert_includes toks, [Rouge::Token::Tokens::Str, '/v1/users']

    toks = tokens("URL=\"${BASE_URL}/v1\"\n")
    assert_includes toks, [Rouge::Token::Tokens::Name::Variable, 'BASE_URL']
  end

  def test_demo_preserves_input
    demo = load_demo
    output = @lexer.lex(demo).map { |_, val| val }.join
    assert_equal demo, output, 'Lexer output does not reconstruct the demo input'
  end

  def test_sample_preserves_input
    sample = load_sample
    output = @lexer.lex(sample).map { |_, val| val }.join
    assert_equal sample, output, 'Lexer output does not reconstruct the sample input'
  end

  def test_no_error_tokens_in_demo
    demo = load_demo
    errors = collect_errors(demo)
    assert_empty errors, "Demo produced error tokens:\n#{format_errors(errors)}"
  end

  def test_no_error_tokens_in_sample
    sample = load_sample
    errors = collect_errors(sample)
    assert_empty errors, "Visual sample produced error tokens:\n#{format_errors(errors)}"
  end

  private

  def tokens(text)
    @lexer.lex(text).map { |tok, val| [tok, val] }
  end

  def load_demo
    File.read(File.join(__dir__, 'demos', 'dotenv'))
  end

  def load_sample
    File.read(File.join(__dir__, 'visual', 'samples', 'dotenv'))
  end

  def collect_errors(text)
    @lexer.lex(text).select { |tok, _| tok == Rouge::Token::Tokens::Error }
  end

  def format_errors(errors)
    errors.map { |_, val| "  #{val.inspect}" }.join("\n")
  end
end
