# frozen_string_literal: true

RSpec.shared_examples 'handles Gitaly errors' do
  describe 'when Gitaly is unavailable' do
    before do
      allow_gitaly_to_raise_error
    end

    it 'returns 503 status' do
      make_request

      expect(response).to have_gitlab_http_status(:service_unavailable)
    end

    it 'sets @gitaly_unavailable to true' do
      make_request

      expect(assigns[:gitaly_unavailable]).to be true
    end

    it 'tracks the exception' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Gitlab::Git::CommandError))

      make_request
    end
  end
end

RSpec.shared_examples 'handles Gitaly errors for request specs' do
  describe 'when Gitaly is unavailable' do
    before do
      allow_gitaly_to_raise_error
    end

    it 'returns 503 status' do
      make_request

      expect(response).to have_gitlab_http_status(:service_unavailable)
    end

    it 'tracks the exception' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Gitlab::Git::CommandError))

      make_request
    end
  end
end

RSpec.shared_examples 'handles Gitaly errors for json format' do
  describe 'when Gitaly is unavailable' do
    before do
      allow_gitaly_to_raise_error
    end

    it 'returns 503 status' do
      make_request

      expect(response).to have_gitlab_http_status(:service_unavailable)
    end

    context 'on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'returns SaaS error message in json' do
        make_request

        expect(json_response['error']).to eq(
          'GitLab is currently unable to handle this request. Please try again later.'
        )
      end
    end

    context 'on self-managed' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns self-managed error message in json' do
        make_request

        expect(json_response['error']).to eq(
          'The git server, Gitaly, is not available at this time. Please contact your administrator.'
        )
      end
    end
  end
end
