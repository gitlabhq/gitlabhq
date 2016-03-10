require 'spec_helper'

describe Gitlab::Gfm::Ast::Syntax::Markdown::CodeBlock do
  let(:text) { "```ruby\ncode block\n```" }

  describe 'token' do
    it 'matches entire text' do
      expect(text).to match described_class.pattern
    end
  end

  describe 'lexeme' do
    let(:lexeme) { Gitlab::Gfm::Ast::Lexer.single(text, described_class) }

    describe '#nodes' do
      subject { lexeme.nodes }
      it { is_expected.to be_empty }
    end

    describe '#leaf?' do
      subject { lexeme.leaf? }
      it { is_expected.to be true }
    end

    describe '#to_s' do
      subject { lexeme.to_s }
      it { is_expected.to eq text }
    end

    describe '#lang' do
      subject { lexeme.lang }
      it { is_expected.to eq 'ruby' }
    end
  end
end
