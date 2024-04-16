# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::PaginatedMergeRequestDiff, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:page) { 1 }
  let(:per_page) { 10 }
  let(:diffable) { merge_request.merge_request_diff }
  let(:diff_files_relation) { diffable.merge_request_diff_files }
  let(:diff_files) { subject.diff_files }

  subject do
    described_class.new(diffable, page, per_page)
  end

  describe '#diff_files' do
    let(:per_page) { 3 }
    let(:paginated_rel) { diff_files_relation.page(page).per(per_page) }

    let(:expected_batch_files) do
      paginated_rel.map(&:new_path)
    end

    it 'returns paginated diff files' do
      expect(diff_files.size).to eq(3)
    end

    it 'returns a valid instance of a DiffCollection' do
      expect(diff_files).to be_a(Gitlab::Git::DiffCollection)
    end

    context 'when first page' do
      it 'returns correct diff files' do
        expect(diff_files.map(&:new_path)).to eq(expected_batch_files)
      end
    end

    context 'when another page' do
      let(:page) { 2 }

      it 'returns correct diff files' do
        expect(diff_files.map(&:new_path)).to eq(expected_batch_files)
      end
    end

    context 'when page is nil' do
      let(:page) { nil }

      it 'returns correct diff files' do
        expected_batch_files =
          diff_files_relation.page(described_class::DEFAULT_PAGE).per(per_page).map(&:new_path)

        expect(diff_files.map(&:new_path)).to eq(expected_batch_files)
      end
    end

    context 'when per_page is nil' do
      let(:per_page) { nil }

      it 'returns correct diff files' do
        expected_batch_files =
          diff_files_relation.page(page).per(described_class::DEFAULT_PER_PAGE).map(&:new_path)

        expect(diff_files.map(&:new_path)).to eq(expected_batch_files)
      end
    end

    context 'when invalid page' do
      let(:page) { 999 }

      it 'returns correct diff files' do
        expect(diff_files.map(&:new_path)).to be_empty
      end
    end

    context 'when last page' do
      it 'returns correct diff files' do
        last_page = diff_files_relation.count - per_page
        collection = described_class.new(diffable, last_page, per_page)

        expected_batch_files = diff_files_relation.page(last_page).per(per_page).map(&:new_path)

        expect(collection.diff_files.map(&:new_path)).to eq(expected_batch_files)
      end
    end

    it 'returns generated value' do
      expect(diff_files.first.generated?).not_to be_nil
    end
  end

  it_behaves_like 'unfoldable diff' do
    subject do
      described_class.new(merge_request.merge_request_diff, page, per_page)
    end
  end

  it_behaves_like 'cacheable diff collection' do
    let(:cacheable_files_count) { per_page }
  end

  it_behaves_like 'unsortable diff files' do
    let(:diffable) { merge_request.merge_request_diff }

    subject do
      described_class.new(merge_request.merge_request_diff, page, per_page)
    end
  end
end
