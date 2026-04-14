# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::CollectionUnfolder, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { build_stubbed(:merge_request) }
  let_it_be(:current_user) { build_stubbed(:user) }

  let(:diff_file) { build(:diff_file) }
  let(:diff_files) do
    instance_double(Gitlab::Git::DiffCollection).tap do |collection|
      allow(collection).to receive(:each).and_yield(diff_file)
    end
  end

  let(:collection) do
    instance_double(
      Gitlab::Diff::FileCollection::Base,
      diff_files: diff_files,
      diff_file_paths: [diff_file.new_path]
    )
  end

  let(:position) { instance_double(Gitlab::Diff::Position, file_path: diff_file.new_path) }
  let(:position_collection) { instance_double(Gitlab::Diff::PositionCollection, unfoldable: unfoldable) }

  subject(:unfolder) { described_class.new(merge_request, current_user) }

  before do
    allow(merge_request).to receive(:note_positions_for_paths)
      .with([diff_file.new_path], current_user)
      .and_return(position_collection)
  end

  context 'when there are unfoldable positions' do
    let(:unfoldable) { [position] }

    before do
      allow(diff_file).to receive(:unfolded?).and_return(true)
      allow(diff_file).to receive(:highlighted_diff_lines=)
    end

    it 'unfolds diff files' do
      expect(collection).to receive(:unfold_diff_files).with([position])

      unfolder.unfold!(collection)
    end

    it 'clears stale highlighted lines on unfolded files' do
      allow(collection).to receive(:unfold_diff_files)

      expect(diff_file).to receive(:highlighted_diff_lines=).with(nil)

      unfolder.unfold!(collection)
    end

    context 'when file is not unfolded' do
      before do
        allow(collection).to receive(:unfold_diff_files)
        allow(diff_file).to receive(:unfolded?).and_return(false)
      end

      it 'does not clear highlighted lines' do
        expect(diff_file).not_to receive(:highlighted_diff_lines=)

        unfolder.unfold!(collection)
      end
    end
  end

  context 'when there are no unfoldable positions' do
    let(:unfoldable) { [] }

    it 'does not unfold' do
      expect(collection).not_to receive(:unfold_diff_files)

      unfolder.unfold!(collection)
    end
  end
end
