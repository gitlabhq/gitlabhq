# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::MergeRequestDiffStream, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:offset_index) { 5 }
  let(:diff_options) { { offset_index: offset_index } }
  let(:diffable) { merge_request.merge_request_diff }
  let(:diff_files_relation) { diffable.merge_request_diff_files }
  let(:diff_files) { subject.diff_files }

  subject do
    described_class.new(diffable, diff_options: diff_options)
  end

  describe '#diff_files' do
    let(:paginated_rel) { diff_files_relation.offset(offset_index) }
    let(:expected_files) { paginated_rel.map(&:new_path) }

    it 'returns paginated diff files' do
      expect(diff_files.size).to eq(diff_files_relation.count - offset_index)
    end

    it 'returns correct diff files' do
      expect(diff_files.map(&:new_path)).to eq(expected_files)
    end

    it 'returns a valid instance of a DiffCollection' do
      expect(diff_files).to be_a(Gitlab::Git::DiffCollection)
    end

    context 'when offset_index is 0' do
      let(:offset_index) { 0 }

      it 'returns all diff files' do
        expected_files = diff_files_relation.map(&:new_path)

        expect(diff_files.map(&:new_path)).to eq(expected_files)
      end
    end

    it 'returns generated value' do
      expect(diff_files.first.generated?).not_to be_nil
    end
  end

  it_behaves_like 'unfoldable diff' do
    subject do
      described_class.new(merge_request.merge_request_diff, diff_options: diff_options)
    end
  end

  it_behaves_like 'cacheable diff collection' do
    let(:cacheable_files_count) { diff_files_relation.count - offset_index }
  end

  it_behaves_like 'unsortable diff files' do
    let(:diffable) { merge_request.merge_request_diff }

    subject do
      described_class.new(merge_request.merge_request_diff, diff_options: diff_options)
    end
  end
end
