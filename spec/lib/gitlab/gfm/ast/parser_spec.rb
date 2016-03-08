require 'spec_helper'

describe Gitlab::Gfm::Ast::Parser do
  let(:parser) { described_class.new(text) }

  describe '#tree' do
    let(:tree) { parser.tree }

    context 'plain text' do
      let(:text) { 'some plain text' }

      it 'returns valid root node' do
        expect(tree).to be_a(Gitlab::Gfm::Ast::Syntax::Content)
      end
    end

    context 'plain text and ruby block' do
      let(:text) { "some text\n\n\n```ruby\nblock\n```" }

      it 'contains two lexemes' do
        expect(tree.nodes.count).to eq 2
      end

      it 'contains valid lexemes' do
        expect(tree.nodes.first).to be_a Gitlab::Gfm::Ast::Syntax::Text
        expect(tree.nodes.second).to be_a Gitlab::Gfm::Ast::Syntax::Markdown::CodeBlock
      end
    end
  end
end
