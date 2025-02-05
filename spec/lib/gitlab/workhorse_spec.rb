# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Workhorse, feature_category: :shared do
  let_it_be(:project) { create(:project, :repository) }
  let(:features) { { 'gitaly-feature-enforce-requests-limits' => 'true' } }

  let(:repository) { project.repository }

  def decode_workhorse_header(array)
    key, value = array
    command, encoded_params = value.split(":")
    params = Gitlab::Json.parse(Base64.urlsafe_decode64(encoded_params))

    [key, command, params]
  end

  before do
    stub_feature_flags(gitaly_enforce_requests_limits: true)
  end

  describe ".send_git_archive" do
    let(:ref) { 'master' }
    let(:format) { 'zip' }
    let(:storage_path) { Gitlab.config.gitlab.repository_downloads_path }
    let(:path) { 'some/path' }
    let(:include_lfs_blobs) { true }
    let(:metadata) { repository.archive_metadata(ref, storage_path, format, append_sha: nil, path: path) }
    let(:cache_disabled) { false }

    subject do
      described_class.send_git_archive(repository, ref: ref, format: format, append_sha: nil, path: path, include_lfs_blobs: include_lfs_blobs)
    end

    before do
      allow(described_class).to receive(:git_archive_cache_disabled?).and_return(cache_disabled)
    end

    def expected_archive_request(repository, metadata, path, include_lfs_blobs)
      Base64.encode64(
        Gitaly::GetArchiveRequest.new(
          repository: repository.gitaly_repository,
          commit_id: metadata['CommitId'],
          prefix: metadata['ArchivePrefix'],
          format: Gitaly::GetArchiveRequest::Format::ZIP,
          path: path,
          include_lfs_blobs: include_lfs_blobs
        ).to_proto
      )
    end

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(subject)

      expect(key).to eq('Gitlab-Workhorse-Send-Data')
      expect(command).to eq('git-archive')
      expect(params).to eq({
        'GitalyServer' => {
          'call_metadata' => features,
          address: Gitlab::GitalyClient.address(project.repository_storage),
          token: Gitlab::GitalyClient.token(project.repository_storage)
        },
        'ArchivePath' => metadata['ArchivePath'],
        'GetArchiveRequest' => expected_archive_request(repository, metadata, path, include_lfs_blobs)
      }.deep_stringify_keys)
    end

    context 'when include_lfs_blobs is disabled' do
      let(:include_lfs_blobs) { false }

      it 'sets the GetArchiveRequest header correctly' do
        _, _, params = decode_workhorse_header(subject)

        expect(params).to include({ 'GetArchiveRequest' => expected_archive_request(repository, metadata, path, include_lfs_blobs) })
      end
    end

    context 'when archive caching is disabled' do
      let(:cache_disabled) { true }

      it 'tells workhorse not to use the cache' do
        _, _, params = decode_workhorse_header(subject)
        expect(params).to include({ 'DisableCache' => true })
      end
    end

    context "when the repository doesn't have an archive file path" do
      before do
        allow(project.repository).to receive(:archive_metadata).and_return({})
      end

      it "raises an error" do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'when path contains certain utf-8 characters' do
      let(:path) { '😬' }

      it 'does not raise an encoding error' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '.send_git_patch' do
    let(:diff_refs) { double(base_sha: "base", head_sha: "head") }

    subject { described_class.send_git_patch(repository, diff_refs) }

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(subject)

      expect(key).to eq("Gitlab-Workhorse-Send-Data")
      expect(command).to eq("git-format-patch")
      expect(params).to eq({
        'GitalyServer' => {
          'call_metadata' => features,
          address: Gitlab::GitalyClient.address(project.repository_storage),
          token: Gitlab::GitalyClient.token(project.repository_storage)
        },
        'RawPatchRequest' => Gitaly::RawPatchRequest.new(
          repository: repository.gitaly_repository,
          left_commit_id: 'base',
          right_commit_id: 'head'
        ).to_json
      }.deep_stringify_keys)
    end
  end

  describe '.channel_websocket' do
    def terminal(ca_pem: nil)
      out = {
        subprotocols: ['foo'],
        url: 'wss://example.com/terminal.ws',
        headers: { 'Authorization' => ['Token x'] },
        max_session_time: 600
      }
      out[:ca_pem] = ca_pem if ca_pem
      out
    end

    def workhorse(ca_pem: nil)
      out = {
        'Channel' => {
          'Subprotocols' => ['foo'],
          'Url' => 'wss://example.com/terminal.ws',
          'Header' => { 'Authorization' => ['Token x'] },
          'MaxSessionTime' => 600
        }
      }
      out['Channel']['CAPem'] = ca_pem if ca_pem
      out
    end

    context 'without ca_pem' do
      subject { described_class.channel_websocket(terminal) }

      it { is_expected.to eq(workhorse) }
    end

    context 'with ca_pem' do
      subject { described_class.channel_websocket(terminal(ca_pem: "foo")) }

      it { is_expected.to eq(workhorse(ca_pem: "foo")) }
    end
  end

  describe '.send_git_diff' do
    let(:diff_refs) { double(base_sha: "base", head_sha: "head") }

    subject { described_class.send_git_diff(repository, diff_refs) }

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(subject)

      expect(key).to eq("Gitlab-Workhorse-Send-Data")
      expect(command).to eq("git-diff")
      expect(params).to eq({
        'GitalyServer' => {
          'call_metadata' => features,
          address: Gitlab::GitalyClient.address(project.repository_storage),
          token: Gitlab::GitalyClient.token(project.repository_storage)
        },
        'RawDiffRequest' => Gitaly::RawDiffRequest.new(
          repository: repository.gitaly_repository,
          left_commit_id: 'base',
          right_commit_id: 'head'
        ).to_json
      }.deep_stringify_keys)
    end
  end

  describe '#verify_api_request!' do
    let(:header_key) { described_class::INTERNAL_API_REQUEST_HEADER }
    let(:payload) { { 'iss' => 'gitlab-workhorse' } }

    it 'accepts a correct header' do
      headers = { header_key => JWT.encode(payload, described_class.secret, 'HS256') }
      expect { call_verify(headers) }.not_to raise_error
    end

    it 'raises an error when the header is not set' do
      expect { call_verify({}) }.to raise_jwt_error
    end

    it 'raises an error when the header is not signed' do
      headers = { header_key => JWT.encode(payload, nil, 'none') }
      expect { call_verify(headers) }.to raise_jwt_error
    end

    it 'raises an error when the header is signed with the wrong key' do
      headers = { header_key => JWT.encode(payload, 'wrongkey', 'HS256') }
      expect { call_verify(headers) }.to raise_jwt_error
    end

    it 'raises an error when the issuer is incorrect' do
      payload['iss'] = 'somebody else'
      headers = { header_key => JWT.encode(payload, described_class.secret, 'HS256') }
      expect { call_verify(headers) }.to raise_jwt_error
    end

    def raise_jwt_error
      raise_error(JWT::DecodeError)
    end

    def call_verify(headers)
      described_class.verify_api_request!(headers)
    end
  end

  describe '.git_http_ok' do
    let(:user) { create(:user) }
    let(:gitaly_params) do
      {
        GitalyServer: {
          call_metadata: call_metadata,
          address: Gitlab::GitalyClient.address('default'),
          token: Gitlab::GitalyClient.token('default')
        }
      }
    end

    let(:repo_path) { 'ignored but not allowed to be empty in gitlab-workhorse' }
    let(:action) { 'info_refs' }
    let(:params) do
      {
        GL_ID: "user-#{user.id}",
        GL_USERNAME: user.username,
        GL_REPOSITORY: "project-#{project.id}",
        ShowAllRefs: false,
        NeedAudit: false
      }
    end

    let(:call_metadata) do
      features.merge({
                       'user_id' => params[:GL_ID],
                       'username' => params[:GL_USERNAME]
                     })
    end

    subject { described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action) }

    it { expect(subject).to include(params) }

    context 'when the repo_type is a wiki' do
      let(:params) do
        {
          GL_ID: "user-#{user.id}",
          GL_USERNAME: user.username,
          GL_REPOSITORY: "wiki-#{project.id}",
          ShowAllRefs: false
        }
      end

      subject { described_class.git_http_ok(repository, Gitlab::GlRepository::WIKI, user, action) }

      it { expect(subject).to include(params) }
    end

    it 'includes a Repository param' do
      repo_param = {
        storage_name: 'default',
        relative_path: project.disk_path + '.git',
        gl_repository: "project-#{project.id}"
      }

      expect(subject[:Repository]).to include(repo_param)
    end

    context "when git_upload_pack action is passed" do
      let(:action) { 'git_upload_pack' }

      it { expect(subject).to include(gitaly_params) }

      context 'show_all_refs enabled' do
        subject { described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action, show_all_refs: true) }

        it { is_expected.to include(ShowAllRefs: true) }
      end

      context 'need_audit enabled' do
        subject { described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action, show_all_refs: true, need_audit: true) }

        it { is_expected.to include(NeedAudit: true) }
      end

      context 'when a feature flag is set for a single project' do
        before do
          stub_feature_flags(gitaly_mep_mep: project)
        end

        it 'sets the flag to true for that project' do
          response = described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action)

          expect(response.dig(:GitalyServer, :call_metadata)).to include('gitaly-feature-enforce-requests-limits' => 'true',
            'gitaly-feature-mep-mep' => 'true')
        end

        it 'sets the flag to false for other projects' do
          other_project = create(:project, :public, :repository)
          response = described_class.git_http_ok(other_project.repository, Gitlab::GlRepository::PROJECT, user, action)

          expect(response.dig(:GitalyServer, :call_metadata)).to include('gitaly-feature-enforce-requests-limits' => 'true',
            'gitaly-feature-mep-mep' => 'false')
        end

        it 'sets the flag to false when there is no project' do
          snippet = create(:personal_snippet, :repository)
          response = described_class.git_http_ok(snippet.repository, Gitlab::GlRepository::SNIPPET, user, action)

          expect(response.dig(:GitalyServer, :call_metadata)).to include('gitaly-feature-enforce-requests-limits' => 'true',
            'gitaly-feature-mep-mep' => 'false')
        end
      end
    end

    context "when git_receive_pack action is passed" do
      let(:action) { 'git_receive_pack' }

      it { expect(subject).to include(gitaly_params) }
    end

    context "when info_refs action is passed" do
      let(:action) { 'info_refs' }

      it { expect(subject).to include(gitaly_params) }

      context 'show_all_refs enabled' do
        subject { described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action, show_all_refs: true) }

        it { is_expected.to include(ShowAllRefs: true) }
      end
    end

    context 'when action passed is not supported by Gitaly' do
      let(:action) { 'download' }

      it { expect { subject }.to raise_exception('Unsupported action: download') }
    end

    context 'when receive_max_input_size has been updated' do
      it 'returns custom git config' do
        allow(Gitlab::CurrentSettings).to receive(:receive_max_input_size) { 1 }

        expect(subject[:GitConfigOptions]).to be_present
      end
    end

    context 'when receive_max_input_size is empty' do
      it 'returns an empty git config' do
        allow(Gitlab::CurrentSettings).to receive(:receive_max_input_size) { nil }

        expect(subject[:GitConfigOptions]).to be_empty
      end
    end

    context 'when remote_ip is available in the application context' do
      it 'includes a RemoteIP params' do
        result = {}
        Gitlab::ApplicationContext.with_context(remote_ip: "1.2.3.4") do
          result = described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action)
        end
        expect(result[:GitalyServer][:call_metadata]['remote_ip']).to eql("1.2.3.4")
      end
    end

    context 'when remote_ip is not available in the application context' do
      it 'does not include RemoteIP params' do
        result = described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action)
        expect(result[:GitalyServer][:call_metadata]).not_to have_key('remote_ip')
      end
    end
  end

  describe '.cleanup_key' do
    let(:key) { 'test-key' }
    let(:value) { 'test-value' }

    subject(:cleanup_key) { described_class.cleanup_key(key) }

    before do
      described_class.set_key_and_notify(key, value)
    end

    it 'deletes the key' do
      expect { cleanup_key }
        .to change { Gitlab::Redis::Workhorse.with { |c| c.exists?(key) } }.from(true).to(false)
    end
  end

  describe '.set_key_and_notify' do
    let(:key) { 'test-key' }
    let(:value) { 'test-value' }

    subject { described_class.set_key_and_notify(key, value, overwrite: overwrite) }

    shared_examples 'set and notify' do
      it 'set and return the same value' do
        is_expected.to eq(value)
      end

      it 'set and notify' do
        expect(Gitlab::Redis::Workhorse).to receive(:with).and_call_original
        expect_any_instance_of(::Redis).to receive(:publish)
          .with(described_class::NOTIFICATION_PREFIX + 'test-key', "test-value")

        subject
      end
    end

    context 'when we set a new key' do
      let(:overwrite) { true }

      it_behaves_like 'set and notify'
    end

    context 'when we set an existing key' do
      let(:old_value) { 'existing-key' }

      before do
        described_class.set_key_and_notify(key, old_value, overwrite: true)
      end

      context 'and overwrite' do
        let(:overwrite) { true }

        it_behaves_like 'set and notify'
      end

      context 'and do not overwrite' do
        let(:overwrite) { false }

        it 'try to set but return the previous value' do
          is_expected.to eq(old_value)
        end

        it 'does not notify' do
          expect_any_instance_of(::Redis).not_to receive(:publish)

          subject
        end
      end
    end
  end

  describe '.detect_content_type' do
    subject { described_class.detect_content_type }

    it 'returns array setting detect content type in workhorse' do
      expect(subject).to eq(%w[Gitlab-Workhorse-Detect-Content-Type true])
    end
  end

  describe '.send_git_blob' do
    include FakeBlobHelpers

    let(:blob) { fake_blob }

    subject { described_class.send_git_blob(repository, blob) }

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(subject)

      expect(key).to eq('Gitlab-Workhorse-Send-Data')
      expect(command).to eq('git-blob')
      expect(params).to eq({
        'GitalyServer' => {
          'call_metadata' => features,
          address: Gitlab::GitalyClient.address(project.repository_storage),
          token: Gitlab::GitalyClient.token(project.repository_storage)
        },
        'GetBlobRequest' => {
          repository: repository.gitaly_repository.to_h,
          oid: blob.id,
          limit: -1
        }
      }.deep_stringify_keys)
    end
  end

  describe '.send_url' do
    let(:url) { 'http://example.com' }
    let(:allow_localhost) { true }
    let(:ssrf_filter) { false }
    let(:allowed_uris) { [] }
    let(:expected_params) do
      {
        'URL' => url,
        'AllowRedirects' => false,
        'AllowLocalhost' => allow_localhost,
        'AllowedURIs' => allowed_uris.map(&:to_s),
        'SSRFFilter' => ssrf_filter,
        'Header' => {},
        'ResponseHeaders' => {},
        'Body' => '',
        'Method' => 'GET'
      }
    end

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(
        described_class.send_url(url)
      )

      expect(key).to eq("Gitlab-Workhorse-Send-Data")
      expect(command).to eq("send-url")
      expect(params).to eq(expected_params)
    end

    context 'when body, headers, response headers and method are specified' do
      let(:body) { 'body' }
      let(:headers) { { Authorization: ['Bearer token'] } }
      let(:response_headers) { { 'CustomHeader' => 'test' } }
      let(:method) { 'POST' }

      let(:expected_params) do
        super().merge(
          'Body' => body,
          'Header' => headers,
          'ResponseHeaders' => { 'CustomHeader' => ['test'] },
          'Method' => method
        ).deep_stringify_keys
      end

      it 'sets everything correctly' do
        key, command, params = decode_workhorse_header(
          described_class.send_url(url, body: body, headers: headers, response_headers: response_headers, method: method)
        )

        expect(key).to eq("Gitlab-Workhorse-Send-Data")
        expect(command).to eq("send-url")
        expect(params).to eq(expected_params)
      end
    end

    context 'when timeouts are set' do
      let(:timeouts) { { open: '5', read: '5' } }
      let(:expected_params) { super().merge('DialTimeout' => '5s', 'ResponseHeaderTimeout' => '5s') }

      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(described_class.send_url(url, timeouts: timeouts))

        expect(key).to eq("Gitlab-Workhorse-Send-Data")
        expect(command).to eq("send-url")
        expect(params).to eq(expected_params)
      end
    end

    context 'when an response statuses are set' do
      let(:response_statuses) { { error: :service_unavailable, timeout: :bad_request } }
      let(:expected_params) { super().merge('ErrorResponseStatus' => 503, 'TimeoutResponseStatus' => 400) }

      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(described_class.send_url(url, response_statuses: response_statuses))

        expect(key).to eq("Gitlab-Workhorse-Send-Data")
        expect(command).to eq("send-url")
        expect(params).to eq(expected_params)
      end
    end

    context 'when `ssrf_filter` parameter is set' do
      let(:ssrf_filter) { true }

      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(described_class.send_url(url, ssrf_filter: ssrf_filter))

        expect(key).to eq('Gitlab-Workhorse-Send-Data')
        expect(command).to eq('send-url')
        expect(params).to eq(expected_params)
      end
    end

    context 'when `allowed_uris` paramter is set' do
      let(:allowed_uris) { [URI('http://172.16.123.1:9000')] }

      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(described_class.send_url(url, allowed_uris: allowed_uris))

        expect(key).to eq('Gitlab-Workhorse-Send-Data')
        expect(command).to eq('send-url')
        expect(params).to eq(expected_params)
      end
    end

    context 'when local requests are not allowed' do
      let(:allow_localhost) { false }

      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(described_class.send_url(url, allow_localhost: allow_localhost))

        expect(key).to eq('Gitlab-Workhorse-Send-Data')
        expect(command).to eq('send-url')
        expect(params).to eq(expected_params)
      end
    end
  end

  describe '.send_scaled_image' do
    let(:location) { 'http://example.com/avatar.png' }
    let(:width) { '150' }
    let(:content_type) { 'image/png' }

    subject { described_class.send_scaled_image(location, width, content_type) }

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(subject)

      expect(key).to eq("Gitlab-Workhorse-Send-Data")
      expect(command).to eq("send-scaled-img")
      expect(params).to eq({
        'Location' => location,
        'Width' => width,
        'ContentType' => content_type
      }.deep_stringify_keys)
    end
  end

  describe '.send_dependency' do
    let(:headers) { { Accept: 'foo', Authorization: 'Bearer asdf1234' } }
    let(:url) { 'https://foo.bar.com/baz' }
    let(:upload_method) { nil }
    let(:upload_url) { nil }
    let(:upload_headers) { {} }
    let(:authorized_upload_response) { {} }
    let(:upload_config) { { method: upload_method, headers: upload_headers, url: upload_url, authorized_upload_response: authorized_upload_response }.compact_blank! }
    let(:ssrf_filter) { false }
    let(:allow_localhost) { true }
    let(:allowed_uris) { [] }

    subject do
      described_class.send_dependency(
        headers, url, upload_config: upload_config, ssrf_filter: ssrf_filter, allow_localhost: allow_localhost, allowed_uris: allowed_uris
      )
    end

    shared_examples 'setting the header correctly' do |ensure_upload_config_field: nil|
      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(subject)
        expected_params = {
          'AllowLocalhost' => allow_localhost,
          'Headers' => headers.transform_values { |v| Array.wrap(v) },
          'SSRFFilter' => ssrf_filter,
          'AllowedURIs' => allowed_uris.map(&:to_s),
          'Url' => url,
          'UploadConfig' => {
            'Method' => upload_method,
            'Url' => upload_url,
            'Headers' => upload_headers.transform_values { |v| Array.wrap(v) },
            'AuthorizedUploadResponse' => authorized_upload_response
          }.compact_blank!
        }
        expected_params.compact_blank!

        expect(key).to eq("Gitlab-Workhorse-Send-Data")
        expect(command).to eq("send-dependency")
        expect(params).to eq(expected_params.deep_stringify_keys)

        expect(params.dig('UploadConfig', ensure_upload_config_field)).to be_present if ensure_upload_config_field
      end
    end

    it_behaves_like 'setting the header correctly'

    context 'overriding the method' do
      let(:upload_method) { 'PUT' }

      it_behaves_like 'setting the header correctly', ensure_upload_config_field: 'Method'
    end

    context 'overriding the upload url' do
      let(:upload_url) { 'https://test.dev' }

      it_behaves_like 'setting the header correctly', ensure_upload_config_field: 'Url'
    end

    context 'with upload headers set' do
      let(:upload_headers) { { 'Private-Token' => '1234567890' } }

      it_behaves_like 'setting the header correctly', ensure_upload_config_field: 'Headers'
    end

    context 'with authorized upload response set' do
      let(:authorized_upload_response) { { 'TempPath' => '/dev/null' } }

      it_behaves_like 'setting the header correctly', ensure_upload_config_field: 'AuthorizedUploadResponse'
    end

    context 'when `ssrf_filter` parameter is set' do
      let(:ssrf_filter) { true }

      it_behaves_like 'setting the header correctly'
    end

    context 'when `allowed_uris` parameter is set' do
      let(:allowed_uris) { [URI('http://172.16.123.1:9000')] }

      it_behaves_like 'setting the header correctly'
    end

    context 'when local requests are not allowed' do
      let(:allow_localhost) { false }

      it_behaves_like 'setting the header correctly'
    end
  end

  describe '.send_git_snapshot' do
    let(:url) { 'http://example.com' }

    subject(:request) { described_class.send_git_snapshot(repository) }

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(request)

      expect(key).to eq("Gitlab-Workhorse-Send-Data")
      expect(command).to eq('git-snapshot')
      expect(params).to eq(
        'GitalyServer' => {
          'call_metadata' => features,
          'address' => Gitlab::GitalyClient.address(project.repository_storage),
          'token' => Gitlab::GitalyClient.token(project.repository_storage)
        },
        'GetSnapshotRequest' => Gitaly::GetSnapshotRequest.new(
          repository: repository.gitaly_repository
        ).to_json
      )
    end
  end
end
