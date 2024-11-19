# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

MOCK_LINE = Struct.new(:text, :type, :index, :old_pos, :new_pos)

def make_lines(old_lines, new_lines, texts = nil, types = nil)
  old_lines.each_with_index.map do |old, i|
    MOCK_LINE.new(texts ? texts[i] : '', types ? types[i] : nil, i, old, new_lines[i])
  end
end

RSpec.describe Gitlab::Diff::Rendered::Notebook::DiffFileHelper do
  let(:dummy) { Class.new { include Gitlab::Diff::Rendered::Notebook::DiffFileHelper }.new }

  describe '#strip_diff_frontmatter' do
    using RSpec::Parameterized::TableSyntax

    subject { dummy.strip_diff_frontmatter(diff) }

    where(:diff, :result) do
      "FileLine1\nFileLine2\n@@ -1,76 +1,74 @@\nhello\n" | "@@ -1,76 +1,74 @@\nhello\n"
      "" | nil
      nil | nil
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#map_transformed_line_to_source' do
    using RSpec::Parameterized::TableSyntax

    subject { dummy.source_line_from_block(1, transformed_blocks) }

    where(:case, :transformed_blocks, :result) do
      'if transformed diff is empty' | [] | 0
      'if the transformed line does not map to any in the original file' | [{ source_line: nil }] | 0
      'if the transformed line maps to a line in the source file' | [{ source_line: 3 }] | 3
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#image_as_rich_text' do
    let(:img) { 'data:image/png;base64,some_image_here' }
    let(:line_text) { "     ![](#{img})" }

    subject { dummy.image_as_rich_text(line_text) }

    context 'text does not contain image' do
      let(:img) { "not an image" }

      it { is_expected.to be_nil }
    end

    context 'text contains image' do
      it { is_expected.to eq("<img src=\"#{img}\">") }
    end

    context 'text contains image that has malicious html' do
      let(:img) { 'data:image/png;base64,some_image_here"<div>Hello</div>' }

      it 'sanitizes the html' do
        expect(subject).not_to include('<div>Hello')
      end

      it 'adds image to src' do
        expect(subject).to end_with('/div&gt;">')
      end
    end
  end

  describe '#line_positions_at_source_diff' do
    using RSpec::Parameterized::TableSyntax

    let(:blocks) do
      {
        from: [1, 3, 2, nil, nil, 4].map { |i| { source_line: i } },
        to: [1, 2, nil, 3, nil, 4].map { |i| { source_line: i } }
      }
    end

    let(:lines) do
      make_lines(
        [1, 2, 3, 4, 5, 5, 5, 5, 6],
        [1, 2, 2, 2, 2, 3, 4, 5, 6],
        'ACBLDJEKF'.split(""),
        [nil, 'old', 'old', 'old', 'new', 'new', 'new', nil, nil]
      )
    end

    subject { dummy.line_positions_at_source_diff(lines, blocks)[index] }

    where(:case, :index, :transformed_positions, :mapped_positions) do
      "  A A" | 0 | [1, 1] | [1, 1] # No change, old_pos and new_pos have mappings
      "- C  " | 1 | [2, 2] | [3, 2] # A removal, both old_pos and new_pos have valid mappings
      "- B  " | 2 | [3, 2] | [2, 2] # A removal, both old_pos and new_pos have valid mappings
      "- L  " | 3 | [4, 2] | [0, 0] # A removal, but old_pos has no mapping
      "+   D" | 4 | [5, 2] | [4, 2] # An addition, new_pos has mapping but old_pos does not, so old_pos is remapped
      "+   J" | 5 | [5, 3] | [0, 0] # An addition, but new_pos has no mapping, so neither are remapped
      "+   E" | 6 | [5, 4] | [4, 3] # An addition, new_pos has mapping but old_pos does not, so old_pos is remapped
      "  K K" | 7 | [5, 5] | [0, 0] # This has no mapping
      "  F F" | 8 | [6, 6] | [4, 4] # No change, old_pos and new_pos have mappings
    end

    with_them do
      it { is_expected.to eq(mapped_positions) }
    end
  end

  describe '#lines_in_source_diff' do
    using RSpec::Parameterized::TableSyntax

    let(:lines) { make_lines(old_lines, new_lines) }

    subject { dummy.lines_in_source_diff(lines, is_deleted, is_new) }

    where(:old_lines, :new_lines, :is_deleted, :is_new, :existing_lines) do
      [1, 2, 2] | [1, 1, 4] | false | false | { from: Set[1, 2], to: Set[1, 4] }
      [1, 2, 2] | [1, 1, 4] | true | false | { from: Set[1, 2], to: Set[] }
      [1, 2, 2] | [1, 1, 4] | false | true | { from: Set[], to: Set[1, 4] }
    end

    with_them do
      it { is_expected.to eq(existing_lines) }
    end
  end
end
