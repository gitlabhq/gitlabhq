require 'spec_helper'

describe Gitlab::Diff::InlineDiffMarker, lib: true do
  describe '#inline_diffs' do
    let(:raw)  { "abc def" }
    let(:rich) { %{<span class="abc">abc</span><span class="space"> </span><span class="def">def</span>} }
    let(:inline_diffs) { [2..4] }

    let(:subject) { Gitlab::Diff::InlineDiffMarker.new(raw, rich).mark(inline_diffs) }

    it 'marks the inline diffs' do
      expect(subject).to eq(%{<span class="abc">ab<span class='idiff'>c</span></span><span class="space"><span class='idiff'> </span></span><span class="def"><span class='idiff'>d</span>ef</span>})
    end
  end
end
