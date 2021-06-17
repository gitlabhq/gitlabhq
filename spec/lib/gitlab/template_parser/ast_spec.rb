# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TemplateParser::AST::Identifier do
  let(:state) { Gitlab::TemplateParser::EvalState.new }

  describe '#evaluate' do
    it 'evaluates a selector' do
      data = { 'number' => 10 }

      expect(described_class.new('number').evaluate(state, data)).to eq(10)
    end

    it 'returns nil if the key is not set' do
      expect(described_class.new('number').evaluate(state, {})).to be_nil
    end

    it 'returns nil if the input is not a Hash' do
      expect(described_class.new('number').evaluate(state, 45)).to be_nil
    end

    it 'returns the current data when using the special identifier "it"' do
      expect(described_class.new('it').evaluate(state, 45)).to eq(45)
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::Integer do
  let(:state) { Gitlab::TemplateParser::EvalState.new }

  describe '#evaluate' do
    it 'evaluates a selector' do
      expect(described_class.new(0).evaluate(state, [10])).to eq(10)
    end

    it 'returns nil if the index is not set' do
      expect(described_class.new(1).evaluate(state, [10])).to be_nil
    end

    it 'returns nil if the input is not an Array' do
      expect(described_class.new(0).evaluate(state, {})).to be_nil
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::Selector do
  let(:state) { Gitlab::TemplateParser::EvalState.new }
  let(:data) { { 'numbers' => [10] } }

  describe '#evaluate' do
    it 'evaluates a selector' do
      ident = Gitlab::TemplateParser::AST::Identifier.new('numbers')
      int = Gitlab::TemplateParser::AST::Integer.new(0)

      expect(described_class.new([ident, int]).evaluate(state, data)).to eq(10)
    end

    it 'evaluates a selector that returns nil' do
      int = Gitlab::TemplateParser::AST::Integer.new(0)

      expect(described_class.new([int]).evaluate(state, data)).to be_nil
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::Variable do
  let(:state) { Gitlab::TemplateParser::EvalState.new }
  let(:data) { { 'numbers' => [10] } }

  describe '#evaluate' do
    it 'evaluates a variable' do
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{{numbers.0}}')
        .nodes[0]

      expect(node.evaluate(state, data)).to eq('10')
    end

    it 'evaluates an undefined variable' do
      node =
        Gitlab::TemplateParser::Parser.new.parse_and_transform('{{foobar}}').nodes[0]

      expect(node.evaluate(state, data)).to eq('')
    end

    it 'evaluates the special variable "it"' do
      node =
        Gitlab::TemplateParser::Parser.new.parse_and_transform('{{it}}').nodes[0]

      expect(node.evaluate(state, data)).to eq(data.to_s)
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::Expressions do
  let(:state) { Gitlab::TemplateParser::EvalState.new }

  describe '#evaluate' do
    it 'evaluates all expressions' do
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{{number}}foo')

      expect(node.evaluate(state, { 'number' => 10 })).to eq('10foo')
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::Text do
  let(:state) { Gitlab::TemplateParser::EvalState.new }

  describe '#evaluate' do
    it 'returns the text' do
      expect(described_class.new('foo').evaluate(state, {})).to eq('foo')
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::If do
  let(:state) { Gitlab::TemplateParser::EvalState.new }

  describe '#evaluate' do
    it 'evaluates a truthy if expression without an else clause' do
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{% if thing %}foo{% end %}')
        .nodes[0]

      expect(node.evaluate(state, { 'thing' => true })).to eq('foo')
    end

    it 'evaluates a falsy if expression without an else clause' do
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{% if thing %}foo{% end %}')
        .nodes[0]

      expect(node.evaluate(state, { 'thing' => false })).to eq('')
    end

    it 'evaluates a falsy if expression with an else clause' do
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{% if thing %}foo{% else %}bar{% end %}')
        .nodes[0]

      expect(node.evaluate(state, { 'thing' => false })).to eq('bar')
    end
  end

  describe '#truthy?' do
    it 'returns true for a non-empty String' do
      expect(described_class.new.truthy?('foo')).to eq(true)
    end

    it 'returns true for a non-empty Array' do
      expect(described_class.new.truthy?([10])).to eq(true)
    end

    it 'returns true for a Boolean true' do
      expect(described_class.new.truthy?(true)).to eq(true)
    end

    it 'returns false for an empty String' do
      expect(described_class.new.truthy?('')).to eq(false)
    end

    it 'returns true for an empty Array' do
      expect(described_class.new.truthy?([])).to eq(false)
    end

    it 'returns false for a Boolean false' do
      expect(described_class.new.truthy?(false)).to eq(false)
    end
  end
end

RSpec.describe Gitlab::TemplateParser::AST::Each do
  let(:state) { Gitlab::TemplateParser::EvalState.new }

  describe '#evaluate' do
    it 'evaluates the expression' do
      data = { 'animals' => [{ 'name' => 'Cat' }, { 'name' => 'Dog' }] }
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{% each animals %}{{name}}{% end %}')
        .nodes[0]

      expect(node.evaluate(state, data)).to eq('CatDog')
    end

    it 'returns an empty string when the input is not a collection' do
      data = { 'animals' => 10 }
      node = Gitlab::TemplateParser::Parser
        .new
        .parse_and_transform('{% each animals %}{{name}}{% end %}')
        .nodes[0]

      expect(node.evaluate(state, data)).to eq('')
    end

    it 'disallows too many nested loops' do
      data = {
        'foo' => [
          {
            'bar' => [
              {
                'baz' => [
                  {
                    'quix' => [
                      {
                        'foo' => [{ 'name' => 'Alice' }]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }

      template = <<~TPL
        {% each foo %}
          {% each bar %}
            {% each baz %}
              {% each quix %}
                {% each foo %}
                  {{name}}
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      TPL

      node =
        Gitlab::TemplateParser::Parser.new.parse_and_transform(template).nodes[0]

      expect { node.evaluate(state, data) }
        .to raise_error(Gitlab::TemplateParser::Error)
    end
  end
end
