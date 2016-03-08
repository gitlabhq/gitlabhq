require 'spec_helper'

describe Gitlab::Gfm::Ast do
  describe '#parse' do
    subject { described_class.parse(text) }
    let(:text) { 'some text' }

    it { is_expected.to be_a Gitlab::Gfm::Ast::Syntax::Content }
  end
end
