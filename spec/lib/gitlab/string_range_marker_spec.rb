# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::StringRangeMarker do
  describe '#mark' do
    def mark_diff(rich = nil)
      raw = 'abc <def>'
      inline_diffs = [2..5]

      described_class.new(raw, rich).mark(inline_diffs) do |text, left:, right:, mode:|
        "LEFT#{text}RIGHT".html_safe
      end
    end

    context "when the rich text is html safe" do
      let(:rich) { %(<span class="abc">abc</span><span class="space"> </span><span class="def">&lt;def&gt;</span>).html_safe }

      it 'marks the inline diffs' do
        expect(mark_diff(rich)).to eq(%(<span class="abc">abLEFTcRIGHT</span><span class="space">LEFT RIGHT</span><span class="def">LEFT&lt;dRIGHTef&gt;</span>))
        expect(mark_diff(rich)).to be_html_safe
      end
    end

    context "when the rich text is not html safe" do
      context 'when rich text equals raw text' do
        it 'marks the inline diffs' do
          expect(mark_diff).to eq(%(abLEFTc <dRIGHTef>))
          expect(mark_diff).not_to be_html_safe
        end
      end

      context 'when rich text doeas not equal raw text' do
        let(:rich)  { "abc <def> differs" }

        it 'marks the inline diffs' do
          expect(mark_diff(rich)).to eq(%(abLEFTc &lt;dRIGHTef&gt; differs))
          expect(mark_diff(rich)).to be_html_safe
        end
      end
    end
  end
end
