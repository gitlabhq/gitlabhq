require 'spec_helper'

describe Gitlab::StringRangeMarker do
  describe '#mark' do
    context "when the rich text is html safe" do
      let(:raw)  { "abc <def>" }
      let(:rich) { %{<span class="abc">abc</span><span class="space"> </span><span class="def">&lt;def&gt;</span>}.html_safe }
      let(:inline_diffs) { [2..5] }
      subject do
        described_class.new(raw, rich).mark(inline_diffs) do |text, left:, right:|
          "LEFT#{text}RIGHT"
        end
      end

      it 'marks the inline diffs' do
        expect(subject).to eq(%{<span class="abc">abLEFTcRIGHT</span><span class="space">LEFT RIGHT</span><span class="def">LEFT&lt;dRIGHTef&gt;</span>})
        expect(subject).to be_html_safe
      end
    end

    context "when the rich text is not html safe" do
      let(:raw)  { "abc <def>" }
      let(:inline_diffs) { [2..5] }
      subject do
        described_class.new(raw).mark(inline_diffs) do |text, left:, right:|
          "LEFT#{text}RIGHT"
        end
      end

      it 'marks the inline diffs' do
        expect(subject).to eq(%{abLEFTc &lt;dRIGHTef&gt;})
        expect(subject).to be_html_safe
      end
    end
  end
end
