# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::WordDiff::Parser do
  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse(diff.lines).to_a }

    let(:diff) do
      <<~EOF
      @@ -1,14 +1,13 @@
      ~
       Unchanged line
      ~
      ~
      -Old change
      +New addition
        unchanged content
      ~
      @@ -50,14 +50,13 @@
      +First change
        same same same_
      -removed_
      +added_
       end of the line
      ~
      ~
      EOF
    end

    it 'returns a collection of lines' do
      diff_lines = subject

      aggregate_failures do
        expect(diff_lines.count).to eq(7)

        expect(diff_lines.map { |line| diff_line_attributes(line) }).to eq(
          [
            { index: 0, old_pos: 1, new_pos: 1, text: '', type: nil, marker_ranges: [] },
            { index: 1, old_pos: 2, new_pos: 2, text: 'Unchanged line', type: nil, marker_ranges: [] },
            { index: 2, old_pos: 3, new_pos: 3, text: '', type: nil, marker_ranges: [] },
            { index: 3, old_pos: 4, new_pos: 4, text: 'Old changeNew addition unchanged content', type: nil,
              marker_ranges: [
                Gitlab::MarkerRange.new(0, 9, mode: :deletion),
                Gitlab::MarkerRange.new(10, 21, mode: :addition)
              ] },

            { index: 4, old_pos: 50, new_pos: 50, text: '@@ -50,14 +50,13 @@', type: 'match', marker_ranges: [] },
            { index: 5, old_pos: 50, new_pos: 50, text: 'First change same same same_removed_added_end of the line', type: nil,
              marker_ranges: [
                Gitlab::MarkerRange.new(0, 11, mode: :addition),
                Gitlab::MarkerRange.new(28, 35, mode: :deletion),
                Gitlab::MarkerRange.new(36, 41, mode: :addition)
              ] },

            { index: 6, old_pos: 51, new_pos: 51, text: '', type: nil, marker_ranges: [] }
          ]
        )
      end
    end

    it 'restarts object index after several calls to Enumerator' do
      enumerator = parser.parse(diff.lines)

      2.times do
        expect(enumerator.first.index).to eq(0)
      end
    end

    context 'when diff is empty' do
      let(:diff) { '' }

      it { is_expected.to eq([]) }
    end
  end

  private

  def diff_line_attributes(diff_line)
    {
      index: diff_line.index,
      old_pos: diff_line.old_pos,
      new_pos: diff_line.new_pos,
      text: diff_line.text,
      type: diff_line.type,
      marker_ranges: diff_line.marker_ranges
    }
  end
end
