require 'spec_helper'

describe Gitlab::Diff::InlineDiffMarker, lib: true do
  describe '#inline_diffs' do

    context "when the rich text is html safe" do
      let(:raw)  { "abc 'def'" }
      let(:rich) { %{<span class="abc">abc</span><span class="space"> </span><span class="def">&#39;def&#39;</span>}.html_safe }
      let(:inline_diffs) { [2..5] }
      let(:subject) { Gitlab::Diff::InlineDiffMarker.new(raw, rich).mark(inline_diffs) }

      it 'marks the inline diffs' do
        expect(subject).to eq(%{<span class="abc">ab<span class='idiff left'>c</span></span><span class="space"><span class='idiff'> </span></span><span class="def"><span class='idiff right'>&#39;d</span>ef&#39;</span>})
        expect(subject).to be_html_safe
      end
    end

    context "when the text text is not html safe" do
      let(:raw)  { "abc 'def'" }
      let(:inline_diffs) { [2..5] }
      let(:subject) { Gitlab::Diff::InlineDiffMarker.new(raw).mark(inline_diffs) }

      it 'marks the inline diffs' do
        expect(subject).to eq(%{ab<span class='idiff left right'>c &#39;d</span>ef&#39;})
        expect(subject).to be_html_safe
      end
    end
  end
end
