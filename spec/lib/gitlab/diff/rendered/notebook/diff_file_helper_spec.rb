# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

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

    subject { dummy.map_transformed_line_to_source(1, transformed_blocks) }

    where(:case, :transformed_blocks, :result) do
      'if transformed diff is empty' | [] | 0
      'if the transformed line does not map to any in the original file' | [{ source_line: nil }] | 0
      'if the transformed line maps to a line in the source file' | [{ source_line: 2 }] | 3
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#map_diff_block_to_source_line' do
    let(:file_added) { false }
    let(:file_deleted) { false }
    let(:old_positions) { [1] }
    let(:new_positions) { [1] }
    let(:lines) { old_positions.zip(new_positions).map { |old, new| Gitlab::Diff::Line.new("", "", 0, old, new) } }

    subject { dummy.map_diff_block_to_source_line(lines, file_added, file_deleted)}

    context 'only additions' do
      let(:old_positions) { [1, 2, 2, 2] }
      let(:new_positions) { [1, 2, 3, 4] }

      it 'computes the removals correctly' do
        expect(subject[0]).to eq({ 1 => 1, 2 => 4 })
      end

      it 'computes the additions correctly' do
        expect(subject[1]).to eq({ 1 => 1, 2 => 2, 3 => 2, 4 => 2 })
      end
    end

    context 'only additions' do
      let(:old_positions) { [1, 2, 3, 4] }
      let(:new_positions) { [1, 2, 2, 2] }

      it 'computes the removals correctly' do
        expect(subject[0]).to eq({ 1 => 1, 2 => 2, 3 => 2, 4 => 2 })
      end

      it 'computes the additions correctly' do
        expect(subject[1]).to eq({ 1 => 1, 2 => 4 })
      end
    end

    context 'with additions and removals' do
      let(:old_positions) { [1, 2, 3, 4, 4, 4] }
      let(:new_positions) { [1, 2, 2, 2, 3, 4] }

      it 'computes the removals correctly' do
        expect(subject[0]).to eq({ 1 => 1, 2 => 2, 3 => 2, 4 => 4 })
      end

      it 'computes the additions correctly' do
        expect(subject[1]).to eq({ 1 => 1, 2 => 4, 3 => 4, 4 => 4 })
      end
    end

    context 'is new file' do
      let(:file_added) { true }

      it 'removals is empty' do
        expect(subject[0]).to be_empty
      end
    end

    context 'is deleted file' do
      let(:file_deleted) { true }

      it 'additions is empty' do
        expect(subject[1]).to be_empty
      end
    end
  end

  describe '#image_as_rich_text' do
    let(:img) { 'data:image/png;base64,some_image_here' }
    let(:line_text) { "     ![](#{img})"}

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
end
