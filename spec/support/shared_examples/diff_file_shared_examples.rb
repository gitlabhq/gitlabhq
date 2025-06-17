# frozen_string_literal: true

RSpec.shared_examples 'diff file endpoint' do
  context 'when the rapid_diffs feature flag is disabled' do
    before do
      stub_feature_flags(rapid_diffs: false)
    end

    it 'returns a 404 status' do
      send_request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

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
