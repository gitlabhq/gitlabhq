# frozen_string_literal: true

RSpec.shared_examples 'with diffs_blobs param' do
  context 'with diffs_blob option' do
    context 'when offset is not given' do
      it 'streams all diffs' do
        go(diff_blobs: true)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).to include(*diff_files.to_a.map(&:file_identifier_hash))
      end
    end

    context 'when offset is given' do
      let(:offset) { 1 }

      it 'streams diffs except the offset' do
        go(diff_blobs: true, offset: offset)

        offset_file_identifier_hashes = diff_files.to_a.take(offset).map(&:file_identifier_hash)
        remaining_file_identifier_hashes = diff_files.to_a.slice(offset..).map(&:file_identifier_hash)

        expect(response).to have_gitlab_http_status(:success)
        expect(response.body).not_to include(*offset_file_identifier_hashes)
        expect(response.body).to include(*remaining_file_identifier_hashes)
      end
    end
  end

  def file_identifier_hashes(diff)
    diff.diffs.diff_files.to_a.map(&:file_identifier_hash)
  end
end
