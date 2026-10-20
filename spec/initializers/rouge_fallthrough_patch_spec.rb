# frozen_string_literal: true

require 'fast_spec_helper'
require 'rouge'

require_relative '../../config/initializers/rouge_fallthrough_patch'

RSpec.describe 'rouge_fallthrough_patch', feature_category: :markdown do
  let(:lexer) { Rouge::Lexers::Ruby.new }

  describe 'Rouge::RegexLexer#fallthrough!' do
    it 'raises Fallthrough without capturing a backtrace' do
      expect { lexer.fallthrough! }.to raise_error(Rouge::RegexLexer::Fallthrough) do |error|
        expect(error.backtrace).to eq([])
      end
    end

    it 'still falls through to later rules' do
      tokens = lexer.lex('foo = bar').map { |token, value| [token.qualname, value] }

      expect(tokens).to eq([
        ['Name', 'foo'], ['Text', ' '], ['Operator', '='], ['Text', ' '], ['Name', 'bar']
      ])
    end
  end

  describe 'unpatched Rouge::RegexLexer#fallthrough!' do
    let(:unpatched_fallthrough) { lexer.method(:fallthrough!).super_method }

    it 'still captures a backtrace' do
      expect { unpatched_fallthrough.call }.to raise_error(Rouge::RegexLexer::Fallthrough) do |error|
        expect(error.backtrace).not_to be_empty,
          'Rouge::RegexLexer#fallthrough! is fixed upstream; remove config/initializers/rouge_fallthrough_patch.rb'
      end
    end
  end
end
