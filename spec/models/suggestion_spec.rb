# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Suggestion do
  let(:suggestion) { create(:suggestion) }

  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:note) }

    context 'when suggestion is applied' do
      before do
        allow(subject).to receive(:applied?).and_return(true)
      end

      it { is_expected.to validate_presence_of(:commit_id) }
    end
  end

  describe '#diff_lines' do
    let(:suggestion) { create(:suggestion, :content_from_repo) }

    it 'returns parsed diff lines' do
      expected_diff_lines = Gitlab::Diff::SuggestionDiff.new(suggestion).diff_lines
      diff_lines = suggestion.diff_lines

      expect(diff_lines.size).to eq(expected_diff_lines.size)
      expect(diff_lines).to all(be_a(Gitlab::Diff::Line))

      expected_diff_lines.each_with_index do |expected_line, index|
        expect(diff_lines[index].to_hash).to eq(expected_line.to_hash)
      end
    end
  end

  describe '#appliable?' do
    let(:suggestion) { build(:suggestion) }

    subject(:appliable) { suggestion.appliable? }

    before do
      allow(suggestion).to receive(:inapplicable_reason).and_return(inapplicable_reason)
    end

    context 'when inapplicable_reason is nil' do
      let(:inapplicable_reason) { nil }

      it { is_expected.to be_truthy }
    end

    context 'when inapplicable_reason is not nil' do
      let(:inapplicable_reason) { :applied }

      it { is_expected.to be_falsey }
    end
  end

  describe '#inapplicable_reason' do
    let(:merge_request) { create(:merge_request) }

    let!(:note) do
      create(
        :diff_note_on_merge_request,
        project: merge_request.project,
        noteable: merge_request
      )
    end

    let(:suggestion) { build(:suggestion, note: note) }

    subject(:inapplicable_reason) { suggestion.inapplicable_reason }

    context 'when suggestion is already applied' do
      let(:suggestion) { build(:suggestion, :applied, note: note) }

      it { is_expected.to eq(:applied) }
    end

    context 'when merge request was merged' do
      before do
        merge_request.mark_as_merged!
      end

      it { is_expected.to eq(:merge_request_merged) }
    end

    context 'when merge request is closed' do
      before do
        merge_request.close!
      end

      it { is_expected.to eq(:merge_request_closed) }
    end

    context 'when source branch is deleted' do
      before do
        merge_request.project.repository.rm_branch(merge_request.author, merge_request.source_branch)
      end

      it { is_expected.to eq(:source_branch_deleted) }
    end

    context 'when content is outdated' do
      before do
        allow(suggestion).to receive(:outdated?).and_return(true)
      end

      it { is_expected.to eq(:outdated) }
    end

    context 'when note is outdated' do
      before do
        allow(note).to receive(:active?).and_return(false)
      end

      it { is_expected.to eq(:outdated) }
    end

    context 'when applicable' do
      it { is_expected.to be_nil }
    end
  end

  describe '#single_line?' do
    subject(:single_line) { suggestion.single_line? }

    context 'when suggestion is for a single line' do
      let(:suggestion) { build(:suggestion, lines_above: 0, lines_below: 0) }

      it { is_expected.to eq(true) }
    end

    context 'when suggestion is for multiple lines' do
      let(:suggestion) { build(:suggestion, lines_above: 2, lines_below: 0) }

      it { is_expected.to eq(false) }
    end
  end
end
