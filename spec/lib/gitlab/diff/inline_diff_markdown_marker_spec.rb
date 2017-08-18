require 'spec_helper'

describe Gitlab::Diff::InlineDiffMarkdownMarker do
  describe '#mark' do
    let(:raw) { "abc 'def'" }
    let(:inline_diffs) { [2..5] }
    let(:subject) { described_class.new(raw).mark(inline_diffs, mode: :deletion) }

    it 'marks the range' do
      expect(subject).to eq("ab{-c &#39;d-}ef&#39;")
      expect(subject).to be_html_safe
    end
  end
end
