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

  context 'with full file parameter' do
    let(:full) { true }
    let(:params) do
      super().merge(full: full)
    end

    it 'returns a successful response' do
      send_request

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'expands the diff file to show full content' do
      send_request

      expect(response).to have_gitlab_http_status(:success)
      expect(response.body).to include('rd-diff-file-component')
    end

    context 'when blob size exceeds max patch bytes' do
      before do
        allow_next_instance_of(Blob) do |blob|
          allow(blob).to receive(:raw_size).and_return(Gitlab::CurrentSettings.diff_max_patch_bytes + 1)
        end
      end

      it 'returns 413 payload too large' do
        send_request

        expect(response).to have_gitlab_http_status(:payload_too_large)
      end
    end

    context 'when blob is nil' do
      it 'returns false' do
        send_request

        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end
end
