# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'rouge-lexer-dotenv'
  s.version     = '0.1.0'
  s.summary     = 'Rouge lexer for .env'
  s.description = 'A Rouge plugin providing syntax highlighting for dotenv (.env) environment variable files'
  s.authors     = ['Sean Whalen']
  s.homepage    = 'https://github.com/seanthegeek/rouge-lexer-dotenv'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb'] + Dir['spec/demos/*'] + Dir['spec/visual/samples/*'] + ['README.md']

  s.required_ruby_version = '>= 3.0'

  # Rouge 3.4.0 is the first release with Name::Variable::Magic; do not lower this
  s.add_dependency 'rouge', '>= 3.4'

  s.metadata = {
    'source_code_uri'   => 'https://github.com/seanthegeek/rouge-lexer-dotenv',
    'bug_tracker_uri'   => 'https://github.com/seanthegeek/rouge-lexer-dotenv/issues',
    'changelog_uri'     => 'https://github.com/seanthegeek/rouge-lexer-dotenv/blob/main/CHANGELOG.md',
    'documentation_uri' => 'https://github.com/seanthegeek/rouge-lexer-dotenv/blob/main/README.md'
  }
end
