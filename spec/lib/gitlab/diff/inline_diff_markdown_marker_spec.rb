# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Diff::InlineDiffMarkdownMarker do
  describe '#mark' do
    let(:raw) { "abc 'def'" }
    let(:inline_diffs) { [Gitlab::MarkerRange.new(2, 5, mode: Gitlab::MarkerRange::DELETION)] }
    let(:subject) { described_class.new(raw).mark(inline_diffs) }

    it 'does not escape html etities and marks the range' do
      expect(subject).to eq("ab{-c 'd-}ef'")
      expect(subject).not_to be_html_safe
    end
  end
end
