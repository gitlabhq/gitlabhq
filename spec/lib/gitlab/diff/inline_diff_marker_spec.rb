# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Diff::InlineDiffMarker do
  describe '#mark' do
    let(:inline_diffs) { [2..5] }
    let(:raw) { "abc 'def'" }

    subject { described_class.new(raw, rich).mark(inline_diffs) }

    context "when the rich text is html safe" do
      let(:rich) { %(<span class="abc">abc</span><span class="space"> </span><span class="def">&#39;def&#39;</span>).html_safe }

      it 'marks the range' do
        expect(subject).to eq(%(<span class="abc">ab<span class="idiff left">c</span></span><span class="space"><span class="idiff"> </span></span><span class="def"><span class="idiff right">&#39;d</span>ef&#39;</span>))
        expect(subject).to be_html_safe
      end
    end

    context "when the text is not html safe" do
      let(:rich) { "abc 'def' differs" }

      it 'marks the range' do
        expect(subject).to eq(%(ab<span class="idiff left right">c &#39;d</span>ef&#39; differs))
        expect(subject).to be_html_safe
      end
    end
  end
end
