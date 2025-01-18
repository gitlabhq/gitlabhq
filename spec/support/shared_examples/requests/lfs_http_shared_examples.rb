# frozen_string_literal: true

RSpec.shared_examples 'LFS http 200 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :ok }
  end
end

RSpec.shared_examples 'LFS http 200 blob response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :ok }
    let(:content_type) { ::Repositories::LfsApiController::LFS_TRANSFER_CONTENT_TYPE }
    let(:response_headers) { { 'X-Sendfile' => lfs_object.file.path } }
  end
end

RSpec.shared_examples 'LFS http 200 workhorse response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :ok }
    let(:content_type) { Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE }
  end
end

RSpec.shared_examples 'LFS http 401 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :unauthorized }
    let(:content_type) { 'text/plain' }
  end
end

RSpec.shared_examples 'LFS http 403 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :forbidden }
    let(:message) { 'Access forbidden. Check your access level.' }
  end
end

RSpec.shared_examples 'LFS http 501 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :not_implemented }
    let(:message) { 'Git LFS is not enabled on this GitLab server, contact your admin.' }
  end
end

RSpec.shared_examples 'LFS http 404 response' do
  it_behaves_like 'LFS http expected response code and message' do
    let(:response_code) { :not_found }
  end
end

RSpec.shared_examples 'LFS http expected response code and message' do
  let(:response_code) {}
  let(:response_headers) { {} }
  let(:content_type) { LfsRequest::CONTENT_TYPE }
  let(:message) {}

  specify do
    expect(response).to have_gitlab_http_status(response_code)
    expect(response.headers.to_hash).to include(response_headers)
    expect(response.media_type).to match(content_type)
    expect(json_response['message']).to eq(message) if message
  end
end

RSpec.shared_examples 'LFS http requests' do
  include LfsHttpHelpers

  let(:lfs_enabled) { true }
  let(:authorize_guest) {}
  let(:authorize_download) {}
  let(:authorize_upload) {}

  let(:lfs_object) { create(:lfs_object, :with_file) }
  let(:sample_oid) { lfs_object.oid }
  let(:sample_size) { lfs_object.size }
  let(:sample_object) { { 'oid' => sample_oid, 'size' => sample_size } }
  let(:non_existing_object_oid) { '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897' }
  let(:non_existing_object_size) { 1575078 }
  let(:non_existing_object) { { 'oid' => non_existing_object_oid, 'size' => non_existing_object_size } }
  let(:multiple_objects) { [sample_object, non_existing_object] }

  let(:authorization) { authorize_user }
  let(:headers) do
    {
      'Authorization' => authorization,
      'X-Sendfile-Type' => 'X-Sendfile'
    }
  end

  let(:request_download) do
    get objects_url(container, sample_oid), params: {}, headers: headers
  end

  let(:request_upload) do
    post_lfs_json batch_url(container), upload_body(multiple_objects), headers
  end

  before do
    stub_lfs_setting(enabled: lfs_enabled)
  end

  context 'when LFS is disabled globally' do
    let(:lfs_enabled) { false }

    describe 'download request' do
      before do
        request_download
      end

      it_behaves_like 'LFS http 501 response'
    end

    describe 'upload request' do
      before do
        request_upload
      end

      it_behaves_like 'LFS http 501 response'
    end
  end

  context 'unauthenticated' do
    let(:headers) { {} }

    describe 'download request' do
      before do
        request_download
      end

      it_behaves_like 'LFS http 401 response'
    end

    describe 'upload request' do
      before do
        request_upload
      end

      it_behaves_like 'LFS http 401 response'
    end
  end

  context 'without access' do
    describe 'download request' do
      before do
        request_download
      end

      it_behaves_like 'LFS http 404 response'
    end

    describe 'upload request' do
      before do
        request_upload
      end

      it_behaves_like 'LFS http 404 response'
    end
  end

  context 'with guest access' do
    before do
      authorize_guest
    end

    describe 'download request' do
      before do
        request_download
      end

      it_behaves_like 'LFS http 404 response'
    end

    describe 'upload request' do
      before do
        request_upload
      end

      it_behaves_like 'LFS http 404 response'
    end
  end

  context 'with download permission' do
    before do
      authorize_download
    end

    describe 'download request' do
      before do
        request_download
      end

      it_behaves_like 'LFS http 200 blob response'

      context 'when container does not exist' do
        def objects_url(*args)
          super.sub(container.full_path, 'missing/path')
        end

        it_behaves_like 'LFS http 404 response'
      end
    end

    describe 'upload request' do
      before do
        request_upload
      end

      it_behaves_like 'LFS http 403 response'
    end
  end

  context 'with upload permission' do
    before do
      authorize_upload
    end

    describe 'upload request' do
      before do
        request_upload
      end

      it_behaves_like 'LFS http 200 response'
    end
  end

  describe 'deprecated API' do
    shared_examples 'deprecated request' do
      before do
        request
      end

      it_behaves_like 'LFS http expected response code and message' do
        let(:response_code) { 501 }
        let(:message) { 'Server supports batch API only, please update your Git LFS client to version 1.0.1 and up.' }
      end
    end

    context 'when fetching LFS object using deprecated API' do
      subject(:request) do
        get deprecated_objects_url(container, sample_oid), params: {}, headers: headers
      end

      it_behaves_like 'deprecated request'
    end

    context 'when handling LFS request using deprecated API' do
      subject(:request) do
        post_lfs_json deprecated_objects_url(container), nil, headers
      end

      it_behaves_like 'deprecated request'
    end

    def deprecated_objects_url(container, oid = nil)
      File.join(["#{container.http_url_to_repo}/info/lfs/objects/", oid].compact)
    end
  end
end
