# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas, feature_category: :deployment_management do
  let(:jwt_secret) { SecureRandom.random_bytes(described_class::SECRET_LENGTH) }

  before do
    allow(described_class).to receive(:secret).and_return(jwt_secret)
  end

  describe '.verify_api_request' do
    let(:payload) { { 'iss' => described_class::JWT_ISSUER, 'aud' => described_class::JWT_AUDIENCE } }

    context 'returns nil if fails to validate the JWT' do
      it 'when secret is wrong' do
        encoded_token = JWT.encode(payload, 'wrong secret', 'HS256')
        headers = { described_class::INTERNAL_API_KAS_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers)).to be_nil
      end

      it 'when issuer is wrong' do
        payload['iss'] = 'wrong issuer'
        encoded_token = JWT.encode(payload, described_class.secret, 'HS256')
        headers = { described_class::INTERNAL_API_KAS_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers)).to be_nil
      end

      it 'when audience is wrong' do
        payload['aud'] = 'wrong audience'
        encoded_token = JWT.encode(payload, described_class.secret, 'HS256')
        headers = { described_class::INTERNAL_API_KAS_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers)).to be_nil
      end
    end

    it 'returns the decoded JWT' do
      encoded_token = JWT.encode(payload, described_class.secret, 'HS256')
      headers = { described_class::INTERNAL_API_KAS_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to eq([
        { 'iss' => described_class::JWT_ISSUER, 'aud' => described_class::JWT_AUDIENCE },
        { 'alg' => 'HS256' }
      ])
    end
  end

  describe '.secret_path' do
    it 'returns default gitlab config' do
      expect(described_class.secret_path).to eq(Gitlab.config.gitlab_kas.secret_file)
    end
  end

  describe '.enabled?' do
    before do
      allow(Gitlab).to receive(:config).and_return(gitlab_config)
    end

    subject { described_class.enabled? }

    context 'gitlab_config is not enabled' do
      let(:gitlab_config) { { 'gitlab_kas' => { 'enabled' => false } } }

      it { is_expected.to be_falsey }
    end

    context 'gitlab_config is enabled' do
      let(:gitlab_config) { { 'gitlab_kas' => { 'enabled' => true } } }

      it { is_expected.to be_truthy }
    end

    context 'enabled is unset' do
      let(:gitlab_config) { { 'gitlab_kas' => {} } }

      it { is_expected.to be_falsey }
    end
  end

  describe '.external_url' do
    it 'returns gitlab_kas external_url config' do
      expect(described_class.external_url).to eq(Gitlab.config.gitlab_kas.external_url)
    end
  end

  describe '.tunnel_url' do
    before do
      stub_config(gitlab_kas: { external_url: external_url })
    end

    let(:external_url) { 'xyz' }

    subject { described_class.tunnel_url }

    context 'with a gitlab_kas.external_k8s_proxy_url setting' do
      let(:external_k8s_proxy_url) { 'abc' }

      before do
        stub_config(gitlab_kas: { external_k8s_proxy_url: external_k8s_proxy_url })
      end

      it { is_expected.to eq(external_k8s_proxy_url) }
    end

    context 'without a gitlab_kas.external_k8s_proxy_url setting' do
      context 'external_url uses wss://' do
        let(:external_url) { 'wss://kas.gitlab.example.com' }

        it { is_expected.to eq('https://kas.gitlab.example.com/k8s-proxy') }
      end

      context 'external_url uses ws://' do
        let(:external_url) { 'ws://kas.gitlab.example.com' }

        it { is_expected.to eq('http://kas.gitlab.example.com/k8s-proxy') }
      end

      context 'external_url uses grpcs://' do
        let(:external_url) { 'grpcs://kas.gitlab.example.com' }

        it { is_expected.to eq('https://kas.gitlab.example.com/k8s-proxy') }
      end

      context 'external_url uses grpc://' do
        let(:external_url) { 'grpc://kas.gitlab.example.com' }

        it { is_expected.to eq('http://kas.gitlab.example.com/k8s-proxy') }
      end
    end
  end

  describe '.tunnel_ws_url' do
    before do
      stub_config(gitlab_kas: { external_url: external_url })
    end

    let(:external_url) { 'xyz' }

    subject { described_class.tunnel_ws_url }

    context 'with a gitlab_kas.external_k8s_proxy_url setting' do
      let(:external_k8s_proxy_url) { 'http://abc' }

      before do
        stub_config(gitlab_kas: { external_k8s_proxy_url: external_k8s_proxy_url })
      end

      it { is_expected.to eq('ws://abc') }
    end

    context 'without a gitlab_kas.external_k8s_proxy_url setting' do
      context 'external_url uses wss://' do
        let(:external_url) { 'wss://kas.gitlab.example.com' }

        it { is_expected.to eq('wss://kas.gitlab.example.com/k8s-proxy') }
      end

      context 'external_url uses ws://' do
        let(:external_url) { 'ws://kas.gitlab.example.com' }

        it { is_expected.to eq('ws://kas.gitlab.example.com/k8s-proxy') }
      end

      context 'external_url uses grpcs://' do
        let(:external_url) { 'grpcs://kas.gitlab.example.com' }

        it { is_expected.to eq('wss://kas.gitlab.example.com/k8s-proxy') }
      end

      context 'external_url uses grpc://' do
        let(:external_url) { 'grpc://kas.gitlab.example.com' }

        it { is_expected.to eq('ws://kas.gitlab.example.com/k8s-proxy') }
      end
    end
  end

  describe '.internal_url' do
    it 'returns gitlab_kas internal_url config' do
      expect(described_class.internal_url).to eq(Gitlab.config.gitlab_kas.internal_url)
    end
  end

  describe 'version information' do
    it 'has valid version_infos' do
      expect(described_class.version_info).to be_valid
      expect(described_class.display_version_info).to be_valid
      expect(described_class.install_version_info).to be_valid
    end

    it 'has a version based on the version_info' do
      expect(described_class.version).to eq described_class.version_info.to_s
    end

    describe 'versioning according to the KAS version file content' do
      before do
        kas_version_file_double = instance_double(File, read: version_file_content)
        allow(Rails.root).to receive(:join).with(Gitlab::Kas::VERSION_FILE).and_return(kas_version_file_double)
      end

      let(:version_file_content) { 'v16.10.1' }

      it 'has a version and version_infos based on the KAS version file' do
        expected_version_string = version_file_content.sub('v', '')

        expect(described_class.version).to eq expected_version_string
        expect(described_class.version_info.to_s).to eq expected_version_string
        expect(described_class.display_version_info.to_s).to eq expected_version_string
        expect(described_class.install_version_info.to_s).to eq expected_version_string
      end

      context 'when the KAS version file content is a release candidate version' do
        let(:version_file_content) { 'v16.10.1-rc42' }

        it 'has a version and version_infos based on the KAS version file' do
          expected_version_string = version_file_content.sub('v', '')

          expect(described_class.version).to eq expected_version_string
          expect(described_class.version_info.to_s).to eq expected_version_string
          expect(described_class.display_version_info.to_s).to eq expected_version_string
          expect(described_class.install_version_info.to_s).to eq expected_version_string
        end
      end

      context 'when the KAS version file content is a SHA' do
        before do
          allow(Gitlab).to receive(:version_info).and_return(gitlab_version_info)
        end

        let(:gitlab_version_info) { Gitlab::VersionInfo.parse('16.11.2') }
        let(:version_file_content) { '5bbaac6e3d907fba9568a2e36aa1e521f589c897' }

        it 'uses the Gitlab version with the SHA as suffix' do
          expected_kas_version = '16.11.2+5bbaac6e3d907fba9568a2e36aa1e521f589c897'

          expect(described_class.version_info.to_s).to eq expected_kas_version
          expect(described_class.version).to eq expected_kas_version
        end

        it 'uses the Gitlab version without suffix as the display_version_info' do
          expect(described_class.display_version_info.to_s).to eq '16.11.2'
        end

        it 'uses the Gitlab version with 0 patch version as the install_version_info' do
          expect(described_class.install_version_info.to_s).to eq '16.11.0'
        end
      end
    end
  end

  describe '.ensure_secret!' do
    context 'secret file exists' do
      before do
        allow(File).to receive(:exist?).with(Gitlab.config.gitlab_kas.secret_file).and_return(true)
      end

      it 'does not call write_secret' do
        expect(described_class).not_to receive(:write_secret)

        described_class.ensure_secret!
      end
    end

    context 'secret file does not exist' do
      before do
        allow(File).to receive(:exist?).with(Gitlab.config.gitlab_kas.secret_file).and_return(false)
      end

      it 'calls write_secret' do
        expect(described_class).to receive(:write_secret)

        described_class.ensure_secret!
      end
    end
  end

  describe '.client_timeout_seconds' do
    context 'when client_timeout_seconds is configured' do
      before do
        allow(Gitlab.config).to receive(:gitlab_kas).and_return({ 'client_timeout_seconds' => 15 })
      end

      it 'returns the configured timeout' do
        expect(described_class.client_timeout_seconds).to eq(15)
      end
    end

    context 'when client_timeout_seconds is not configured' do
      before do
        allow(Gitlab.config).to receive(:gitlab_kas).and_return({ 'client_timeout_seconds' => nil })
      end

      it 'returns the default timeout' do
        expect(described_class.client_timeout_seconds).to eq(5) # Default timeout
      end
    end

    context 'when the configuration is missing' do
      before do
        allow(Gitlab.config).to receive(:gitlab_kas).and_return(nil)
      end

      it 'returns the default timeout' do
        expect(described_class.client_timeout_seconds).to eq(5) # Default timeout
      end
    end
  end
end
