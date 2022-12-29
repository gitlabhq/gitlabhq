# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaginatedDiffEntity do
  let(:user) { create(:user) }
  let(:request) { double('request', current_user: user) }
  let(:merge_request) { create(:merge_request) }
  let(:diff_batch) { merge_request.merge_request_diff.diffs_in_batch(2, 3, diff_options: nil) }
  let(:options) do
    {
      request: request,
      merge_request: merge_request,
      pagination_data: diff_batch.pagination_data
    }
  end

  let(:entity) { described_class.new(diff_batch, options) }

  subject { entity.as_json }

  it 'exposes diff_files' do
    expect(subject[:diff_files]).to be_present
  end

  it 'exposes pagination data' do
    expect(subject[:pagination]).to eq(total_pages: 20)
  end

  describe 'diff_files' do
    let(:diff_files) { diff_batch.diff_files(sorted: true) }

    it 'serializes diff files using DiffFileEntity' do
      expect(DiffFileEntity)
        .to receive(:represent)
        .with(
          diff_files,
          hash_including(options.merge(conflicts: nil))
        )

      subject[:diff_files]
    end

    context 'when there are conflicts' do
      let(:conflict_file) { double(path: diff_files.first.new_path, conflict_type: :both_modified) }
      let(:conflicts) { double(conflicts: double(files: [conflict_file]), can_be_resolved_in_ui?: false) }

      before do
        allow(merge_request).to receive(:cannot_be_merged?).and_return(true)
        allow(MergeRequests::Conflicts::ListService).to receive(:new).and_return(conflicts)
      end

      it 'serializes diff files with conflicts' do
        expect(DiffFileEntity)
          .to receive(:represent)
          .with(
            diff_files,
            hash_including(options.merge(conflicts: { conflict_file.path => conflict_file }))
          )

        subject[:diff_files]
      end
    end
  end
end
