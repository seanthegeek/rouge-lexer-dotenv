# frozen_string_literal: true

require 'rouge'
require_relative 'lib/rouge/lexer/dotenv'

lexer = Rouge::Lexer.find('dotenv')

sample_path = File.join(__dir__, 'spec', 'visual', 'samples', 'dotenv')
sample = File.read(sample_path)

if ENV['DEBUG']
  lexer.lex(sample) { |tok, val| puts "#{tok.qualname.ljust(30)} #{val.inspect}" }
else
  formatter = Rouge::Formatters::Terminal256.new(Rouge::Themes::Github.new)
  puts formatter.format(lexer.lex(sample))
end
