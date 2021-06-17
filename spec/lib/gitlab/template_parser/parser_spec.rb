# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TemplateParser::Parser do
  let(:parser) { described_class.new }

  describe '#root' do
    it 'parses an empty template' do
      expect(parser.root).to parse('')
    end

    it 'parses a variable with a single identifier step' do
      expect(parser.root).to parse('{{foo}}')
    end

    it 'parses a variable with a single integer step' do
      expect(parser.root).to parse('{{0}}')
    end

    it 'parses a variable with multiple selector steps' do
      expect(parser.root).to parse('{{foo.bar}}')
    end

    it 'parses a variable with an integer selector step' do
      expect(parser.root).to parse('{{foo.bar.0}}')
    end

    it 'parses the special "it" variable' do
      expect(parser.root).to parse('{{it}}')
    end

    it 'parses a text node' do
      expect(parser.root).to parse('foo')
    end

    it 'parses an if expression' do
      expect(parser.root).to parse('{% if foo %}bar{% end %}')
    end

    it 'parses an if-else expression' do
      expect(parser.root).to parse('{% if foo %}bar{% else %}baz{% end %}')
    end

    it 'parses an each expression' do
      expect(parser.root).to parse('{% each foo %}foo{% end %}')
    end

    it 'parses an escaped newline' do
      expect(parser.root).to parse("foo\\\nbar")
    end

    it 'parses a regular newline' do
      expect(parser.root).to parse("foo\nbar")
    end

    it 'parses the default changelog template' do
      expect(parser.root).to parse(Gitlab::Changelog::Config::DEFAULT_TEMPLATE)
    end

    it 'raises an error when parsing an integer selector that is too large' do
      expect(parser.root).not_to parse('{{100000000000}}')
    end
  end

  describe '#parse_and_transform' do
    it 'parses and transforms a template' do
      node = parser.parse_and_transform('foo')

      expect(node).to be_instance_of(Gitlab::TemplateParser::AST::Expressions)
    end

    it 'raises parsing errors using a custom error class' do
      expect { parser.parse_and_transform('{% each') }
        .to raise_error(Gitlab::TemplateParser::Error)
    end
  end
end
