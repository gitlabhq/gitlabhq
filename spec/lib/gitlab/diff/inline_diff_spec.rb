# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::InlineDiff do
  describe '#inline_diffs' do
    subject { described_class.new(old_line, new_line, offset: offset).inline_diffs }

    let(:old_line) { 'XXX def initialize(test = true)' }
    let(:new_line) { 'YYY def initialize(test = false)' }
    let(:offset) { 3 }

    it 'finds the inline diff', :aggregate_failures do
      expect(subject[0]).to eq([Gitlab::MarkerRange.new(26, 28, mode: :deletion)])
      expect(subject[1]).to eq([Gitlab::MarkerRange.new(26, 29, mode: :addition)])
    end

    context 'when lines have multiple changes' do
      let(:old_line) { '- Hello, how are you?' }
      let(:new_line) { '+ Hi, how are you doing?' }
      let(:offset) { 1 }

      it 'finds all inline diffs', :aggregate_failures do
        expect(subject[0]).to eq([Gitlab::MarkerRange.new(3, 6, mode: :deletion)])
        expect(subject[1]).to eq([
          Gitlab::MarkerRange.new(3, 3, mode: :addition),
                                   Gitlab::MarkerRange.new(17, 22, mode: :addition)
        ])
      end
    end
  end
end
