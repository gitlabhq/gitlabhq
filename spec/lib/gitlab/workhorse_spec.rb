# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Workhorse do
  set(:project)    { create(:project, :repository) }
  let(:repository) { project.repository }

  def decode_workhorse_header(array)
    key, value = array
    command, encoded_params = value.split(":")
    params = JSON.parse(Base64.urlsafe_decode64(encoded_params))

    [key, command, params]
  end

  before do
    allow(Feature::Gitaly).to receive(:server_feature_flags).and_return({
      'gitaly-feature-foobar' => 'true'
    })
  end

  describe ".send_git_archive" do
    let(:ref) { 'master' }
    let(:format) { 'zip' }
    let(:storage_path) { Gitlab.config.gitlab.repository_downloads_path }
    let(:path) { 'some/path' if Feature.enabled?(:git_archive_path, default_enabled: true) }
    let(:metadata) { repository.archive_metadata(ref, storage_path, format, append_sha: nil, path: path) }
    let(:cache_disabled) { false }

    subject do
      described_class.send_git_archive(repository, ref: ref, format: format, append_sha: nil, path: path)
    end

    before do
      allow(described_class).to receive(:git_archive_cache_disabled?).and_return(cache_disabled)
    end

    context 'feature flag disabled' do
      before do
        stub_feature_flags(git_archive_path: false)
      end

      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(subject)

        expected_params = metadata.merge(
          'GitalyRepository' => repository.gitaly_repository.to_h,
          'GitalyServer' => {
            features: { 'gitaly-feature-foobar' => 'true' },
            address: Gitlab::GitalyClient.address(project.repository_storage),
            token: Gitlab::GitalyClient.token(project.repository_storage)
          }
        )

        expect(key).to eq('Gitlab-Workhorse-Send-Data')
        expect(command).to eq('git-archive')
        expect(params).to eq(expected_params.deep_stringify_keys)
      end

      context 'when archive caching is disabled' do
        let(:cache_disabled) { true }

        it 'tells workhorse not to use the cache' do
          _, _, params = decode_workhorse_header(subject)
          expect(params).to include({ 'DisableCache' => true })
        end
      end
    end

    context 'feature flag enabled' do
      it 'sets the header correctly' do
        key, command, params = decode_workhorse_header(subject)

        expect(key).to eq('Gitlab-Workhorse-Send-Data')
        expect(command).to eq('git-archive')
        expect(params).to eq({
          'GitalyServer' => {
            features: { 'gitaly-feature-foobar' => 'true' },
            address: Gitlab::GitalyClient.address(project.repository_storage),
            token: Gitlab::GitalyClient.token(project.repository_storage)
          },
          'ArchivePath' => metadata['ArchivePath'],
          'GetArchiveRequest' => Base64.encode64(
            Gitaly::GetArchiveRequest.new(
              repository: repository.gitaly_repository,
              commit_id: metadata['CommitId'],
              prefix: metadata['ArchivePrefix'],
              format: Gitaly::GetArchiveRequest::Format::ZIP,
              path: path
            ).to_proto
          )
        }.deep_stringify_keys)
      end

      context 'when archive caching is disabled' do
        let(:cache_disabled) { true }

        it 'tells workhorse not to use the cache' do
          _, _, params = decode_workhorse_header(subject)
          expect(params).to include({ 'DisableCache' => true })
        end
      end
    end

    context "when the repository doesn't have an archive file path" do
      before do
        allow(project.repository).to receive(:archive_metadata).and_return(Hash.new)
      end

      it "raises an error" do
        expect { subject }.to raise_error(RuntimeError)
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
          features: { 'gitaly-feature-foobar' => 'true' },
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
          features: { 'gitaly-feature-foobar' => 'true' },
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
    let(:repo_path) { 'ignored but not allowed to be empty in gitlab-workhorse' }
    let(:action) { 'info_refs' }
    let(:params) do
      {
        GL_ID: "user-#{user.id}",
        GL_USERNAME: user.username,
        GL_REPOSITORY: "project-#{project.id}",
        ShowAllRefs: false
      }
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

    context 'when Gitaly is enabled' do
      let(:gitaly_params) do
        {
          GitalyServer: {
            features: { 'gitaly-feature-foobar' => 'true' },
            address: Gitlab::GitalyClient.address('default'),
            token: Gitlab::GitalyClient.token('default')
          }
        }
      end

      before do
        allow(Gitlab.config.gitaly).to receive(:enabled).and_return(true)
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
        let(:feature_flag) { :post_upload_pack }

        it 'includes Gitaly params in the returned value' do
          allow(Gitlab::GitalyClient).to receive(:feature_enabled?).with(feature_flag).and_return(true)

          expect(subject).to include(gitaly_params)
        end

        context 'show_all_refs enabled' do
          subject { described_class.git_http_ok(repository, Gitlab::GlRepository::PROJECT, user, action, show_all_refs: true) }

          it { is_expected.to include(ShowAllRefs: true) }
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
        expect(Gitlab::Redis::SharedState).to receive(:with).and_call_original
        expect_any_instance_of(::Redis).to receive(:publish)
          .with(described_class::NOTIFICATION_CHANNEL, "test-key=test-value")

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
          features: { 'gitaly-feature-foobar' => 'true' },
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

    subject { described_class.send_url(url) }

    it 'sets the header correctly' do
      key, command, params = decode_workhorse_header(subject)

      expect(key).to eq("Gitlab-Workhorse-Send-Data")
      expect(command).to eq("send-url")
      expect(params).to eq({
        'URL' => url,
        'AllowRedirects' => false
      }.deep_stringify_keys)
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
          'features' => { 'gitaly-feature-foobar' => 'true' },
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
