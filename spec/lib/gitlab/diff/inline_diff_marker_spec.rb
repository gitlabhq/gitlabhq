require 'spec_helper'

describe Gitlab::Diff::InlineDiffMarker, lib: true do
  describe '#inline_diffs' do
    let(:raw)  { "abc 'def'" }
    let(:rich) { %{<span class="abc">abc</span><span class="space"> </span><span class="def">&#39;def&#39;</span>} }
    let(:inline_diffs) { [2..5] }

    let(:subject) { Gitlab::Diff::InlineDiffMarker.new(raw, rich).mark(inline_diffs) }

    it 'marks the inline diffs' do
      expect(subject).to eq(%{<span class="abc">ab<span class='idiff'>c</span></span><span class="space"><span class='idiff'> </span></span><span class="def"><span class='idiff'>&#39;d</span>ef&#39;</span>})
    end
  end
end
