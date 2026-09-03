# rouge-lexer-dotenv

[![Test](https://github.com/seanthegeek/rouge-lexer-dotenv/actions/workflows/test.yml/badge.svg)](https://github.com/seanthegeek/rouge-lexer-dotenv/actions/workflows/test.yml)
[![Gem Version](https://badge.fury.io/rb/rouge-lexer-dotenv.svg)](https://rubygems.org/gems/rouge-lexer-dotenv)

A Rouge lexer plugin for dotenv (.env) environment variable files. Rouge is the
default syntax highlighter for Jekyll (and therefore GitHub Pages). This gem adds
.env support to Rouge.

## Installation

The gem requires Ruby 3.0 or newer and Rouge 3.4 or newer.

Install the gem directly:

```sh
gem install rouge-lexer-dotenv
```

Or add it to your `Gemfile`:

```ruby
gem 'rouge-lexer-dotenv'
```

Then run:

```sh
bundle install
```

## Usage

Once installed, Rouge will automatically discover the lexer. You can use
`dotenv` as the language tag in fenced code blocks (see the
lexer definition for additional aliases):

````markdown
```dotenv
# your code here
```
````

### Jekyll / GitHub Pages

Add the gem to your site's `Gemfile` inside the `:jekyll_plugins` group:

```ruby
group :jekyll_plugins do
  gem "rouge-lexer-dotenv"
end
```

Run `bundle install`, then use the language tag in fenced code blocks. Jekyll
will pick up the lexer automatically via Rouge's plugin discovery.

````markdown
```dotenv
# Database
DATABASE_URL="postgres://user:pass@localhost:5432/mydb"
DATABASE_POOL_SIZE=10

BASE_URL=https://api.example.com
FULL_URL=${BASE_URL}/v1/users
```
````

The aliases `env`, `.env` and `environment` work too:

````markdown
```env
ENABLE_CACHE=true
```
````

### Colors

The lexer tells Rouge how to identify tokens. Rouge wraps each token in a `span` tag
with a `class` related to that token type. If you want to change how the tokens are
highlighted, change themes or add custom CSS.

## Development

Install dependencies:

```sh
bundle install
```

Run the test suite:

```sh
bundle exec rake
```

Start the visual preview server (available at http://localhost:9292):

```sh
bundle exec rake server
```

Run the terminal preview script:

```sh
ruby preview.rb
```

Enable debug mode to print each token and its value:

```sh
DEBUG=1 ruby preview.rb
```

### Iterative testing workflow

1. Run `bundle exec rake` to check for test failures and error tokens.
2. Start the server with `bundle exec rake server`.
3. In another terminal, check for error tokens in the rendered output:

   ```sh
   curl -s http://localhost:9292 | grep 'class="err"'
   ```

4. Fix any error tokens in `lib/rouge/lexers/dotenv.rb`.
5. Repeat until no error tokens remain.

## License

MIT
