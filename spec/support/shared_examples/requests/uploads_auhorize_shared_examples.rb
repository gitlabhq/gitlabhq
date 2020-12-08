# frozen_string_literal: true

RSpec.shared_examples 'handle uploads authorize request' do
  before do
    login_as(user)
  end

  describe 'POST authorize' do
    it 'authorizes workhorse header' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      expect(json_response['TempPath']).to eq(uploader_class.workhorse_local_upload_path)
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      expect { subject }.to raise_error(JWT::DecodeError)
    end

    context 'when using remote storage' do
      context 'when direct upload is enabled' do
        before do
          stub_uploads_object_storage(uploader_class, enabled: true, direct_upload: true)
        end

        it 'responds with status 200, location of file remote store and object details' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response).not_to have_key('TempPath')
          expect(json_response['RemoteObject']).to have_key('ID')
          expect(json_response['RemoteObject']).to have_key('GetURL')
          expect(json_response['RemoteObject']).to have_key('StoreURL')
          expect(json_response['RemoteObject']).to have_key('DeleteURL')
          expect(json_response['RemoteObject']).to have_key('MultipartUpload')
          expect(json_response['MaximumSize']).to eq(maximum_size)
        end
      end

      context 'when direct upload is disabled' do
        before do
          stub_uploads_object_storage(uploader_class, enabled: true, direct_upload: false)
        end

        it 'handles as a local file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response['TempPath']).to eq(uploader_class.workhorse_local_upload_path)
          expect(json_response['RemoteObject']).to be_nil
          expect(json_response['MaximumSize']).to eq(maximum_size)
        end
      end
    end
  end
end
