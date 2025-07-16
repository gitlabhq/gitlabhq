# frozen_string_literal: true

RSpec.shared_examples 'diff file endpoint' do
  context 'when diff_file is not found' do
    let(:old_path) { 'bad/path' }
    let(:new_path) { 'bad/path' }

    it 'returns 404 when file is not found' do
      send_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'with an existing file' do
    it 'returns a successful response' do
      send_request
      expect(response).to have_gitlab_http_status(:success)
    end
  end
end
