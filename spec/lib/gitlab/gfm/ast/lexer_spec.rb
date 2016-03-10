require 'spec_helper'

describe Gitlab::Gfm::Ast::Lexer do
  let(:lexer) { described_class.new(text, tokens) }
  let(:nodes) { lexer.process! }

  context 'order of tokens' do
    let(:tokens) do
      [Gitlab::Gfm::Ast::Syntax::Text,
       Gitlab::Gfm::Ast::Syntax::Markdown::CodeBlock]
    end

    let(:text) { "text and ```ruby\nblock\n```" }

    it 'greedily matches tokens in order those are defined' do
      expect(nodes.count).to eq 1
      expect(nodes.first).to be_a Gitlab::Gfm::Ast::Syntax::Text
    end
  end

  context 'uncovered ranges' do
    let(:tokens) do
      [Gitlab::Gfm::Ast::Syntax::Markdown::CodeBlock]
    end

    let(:text) { "text and ```ruby\nblock\n```" }

    it 'raises error when uncovered ranges remain' do
      expect { nodes }.to raise_error(Gitlab::Gfm::Ast::Lexer::LexerError,
                                      /Unprocessed nodes detected/)
    end
  end

  context 'intersecting tokens' do
    let(:tokens) do
      [Gitlab::Gfm::Ast::Syntax::Markdown::CodeBlock,
       Gitlab::Gfm::Ast::Syntax::Text]
    end

    let(:text) { "```ruby\nsome text\n```" }

    it 'does not match intersecting tokens' do
      expect(nodes.count).to eq 1
      expect(nodes.first.nodes.count).to eq 0
    end
  end
end
