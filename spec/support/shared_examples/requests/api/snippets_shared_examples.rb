# frozen_string_literal: true

RSpec.shared_examples 'raw snippet files' do
  let_it_be(:unauthorized_user) { create(:user) }
  let(:snippet_id) { snippet.id }
  let(:user)       { snippet.author }
  let(:file_path)  { '%2Egitattributes' }
  let(:ref)        { 'master' }

  context 'with no user' do
    it 'requires authentication' do
      get api(api_path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'not found' do
    it 'returns 404' do
      get api(api_path, user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end
  end

  context 'when not authorized' do
    let(:user) { unauthorized_user }

    it_behaves_like 'not found'
  end

  context 'with an invalid snippet ID' do
    let(:snippet_id) { 'invalid' }

    it_behaves_like 'not found'
  end

  context 'with valid params' do
    it 'returns the raw file info' do
      expect(Gitlab::Workhorse).to receive(:send_git_blob).and_call_original

      get api(api_path, user)

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq 'text/plain'
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        expect(response.header['Content-Disposition']).to match 'filename=".gitattributes"'
      end
    end
  end

  context 'with invalid params' do
    using RSpec::Parameterized::TableSyntax

    where(:file_path, :ref, :status, :key, :message) do
      '%2Egitattributes'      | 'invalid-ref' | :not_found   | 'message' | '404 Reference Not Found'
      '%2Egitattributes'      | nil           | :not_found   | 'error'   | '404 Not Found'
      '%2Egitattributes'      | ''            | :not_found   | 'error'   | '404 Not Found'

      'doesnotexist.rb'       | 'master'      | :not_found   | 'message' | '404 File Not Found'
      '/does/not/exist.rb'    | 'master'      | :not_found   | 'error'   | '404 Not Found'
      '%2E%2E%2Fetc%2Fpasswd' | 'master'      | :bad_request | 'error'   | 'file_path should be a valid file path'
      '%2Fetc%2Fpasswd'       | 'master'      | :bad_request | 'error'   | 'file_path should be a valid file path'
      '../../etc/passwd'      | 'master'      | :not_found   | 'error'   | '404 Not Found'
    end

    with_them do
      before do
        get api(api_path, user)
      end

      it { expect(response).to have_gitlab_http_status(status) }
      it { expect(json_response[key]).to eq(message) }
    end
  end
end
