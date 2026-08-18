# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::LinkedLineUnfolder, feature_category: :code_review_workflow do
  let(:diff_file) { build(:diff_file) }

  describe '.from_param' do
    it 'builds an unfolder for a context line id' do
      expect(described_class.from_param("line_#{diff_file.short_file_hash}_20")).to be_a(described_class)
    end

    it 'returns nil for an added line id' do
      expect(described_class.from_param("line_#{diff_file.short_file_hash}_A20")).to be_nil
    end

    it 'returns nil for a malformed id' do
      expect(described_class.from_param('not-a-line-id')).to be_nil
    end

    it 'returns nil when the id is not a string' do
      expect(described_class.from_param(nil)).to be_nil
    end
  end

  describe '#unfold!' do
    subject(:unfolder) { described_class.from_param("line_#{diff_file.short_file_hash}_20") }

    it 'unfolds the diff file up to the linked line' do
      expect(diff_file).to receive(:unfold_diff_lines) do |position|
        expect(position).to be_unfoldable
        expect(position.old_line).to eq(20)
        expect(position.old_path).to eq(diff_file.old_path)
        expect(position.new_path).to eq(diff_file.new_path)
      end

      unfolder.unfold!(diff_file)
    end
  end
end
