# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::ViewerHunk, feature_category: :code_review_workflow do
  let(:header) { match_line }
  let(:lines) { [new_line, old_line] }
  let(:hunk) do
    described_class.new(
      header: header,
      lines: lines,
      prev: nil
    )
  end

  describe '#init_from_diff_lines' do
    it 'returns empty array for empty lines' do
      expect(described_class.init_from_diff_lines([])).to be_empty
    end

    it 'returns an array of hunks' do
      lines = [match_line, new_line]
      instance = described_class.init_from_diff_lines(lines)[0]
      expect(instance.header).to eq(lines[0])
      expect(instance.lines).to eq([lines[1]])
    end

    it 'contains all lines' do
      lines = [match_line, new_line, old_line]
      instance = described_class.init_from_diff_lines(lines)[0]
      expect(instance.header).to eq(lines[0])
      expect(instance.lines).to eq(lines.drop(1))
    end

    it 'can return hunk with no header' do
      lines = [new_line]
      instance = described_class.init_from_diff_lines(lines)[0]
      expect(instance.header).to be_nil
      expect(instance.lines).to eq([lines[0]])
    end

    it 'links to previous hunk' do
      lines = [new_line, match_line, old_line]
      instance = described_class.init_from_diff_lines(lines)[1]
      expect(instance.prev.lines).to eq([lines[0]])
    end
  end

  describe '#expand_directions' do
    it 'returns both' do
      lines = [old_line(old_pos: 1), match_line, new_line(old_pos: 5)]
      instance = described_class.init_from_diff_lines(lines)[1]
      expect(instance.expand_directions).to eq([:both])
    end

    it 'returns up' do
      lines = [match_line, new_line(old_pos: 5)]
      instance = described_class.init_from_diff_lines(lines)[0]
      expect(instance.expand_directions).to eq([:up])
    end

    it 'returns down' do
      lines = [old_line(old_pos: 1), match_line(index: nil)]
      instance = described_class.init_from_diff_lines(lines)[1]
      expect(instance.expand_directions).to eq([:down])
    end

    it 'returns up and down' do
      lines = [old_line(old_pos: 1), match_line, new_line(old_pos: 25)]
      instance = described_class.init_from_diff_lines(lines)[1]
      expect(instance.expand_directions).to eq([:down, :up])
    end
  end

  describe '#header_text' do
    it { expect(hunk.header_text).to eq(header.text) }
  end

  describe '#lines' do
    it { expect(hunk.lines).to eq(lines) }
  end

  describe '#parallel_lines' do
    it do
      expect(hunk.parallel_lines.first[:right]).to be_instance_of(Gitlab::Diff::Line)
      expect(hunk.parallel_lines.second[:left]).to be_instance_of(Gitlab::Diff::Line)
    end
  end

  def match_line(index: 0)
    Gitlab::Diff::Line.new(
      '@@ -3,25 +3,11 @@',
      'match',
      index,
      10,
      11
    )
  end

  def new_line(old_pos: 11)
    Gitlab::Diff::Line.new(
      'new line',
      'new',
      0,
      old_pos,
      12
    )
  end

  def old_line(old_pos: 11)
    Gitlab::Diff::Line.new(
      'old line',
      'old',
      0,
      old_pos,
      12
    )
  end
end
