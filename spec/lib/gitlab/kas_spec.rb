# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas do
  let(:jwt_secret) { SecureRandom.random_bytes(described_class::SECRET_LENGTH) }

  before do
    allow(described_class).to receive(:secret).and_return(jwt_secret)
  end

  describe '.verify_api_request' do
    let(:payload) { { 'iss' => described_class::JWT_ISSUER } }

    it 'returns nil if fails to validate the JWT' do
      encoded_token = JWT.encode(payload, 'wrongsecret', 'HS256')
      headers = { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to be_nil
    end

    it 'returns the decoded JWT' do
      encoded_token = JWT.encode(payload, described_class.secret, 'HS256')
      headers = { described_class::INTERNAL_API_REQUEST_HEADER => encoded_token }

      expect(described_class.verify_api_request(headers)).to eq([{ "iss" => described_class::JWT_ISSUER }, { "alg" => "HS256" }])
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

  describe '.version' do
    it 'returns gitlab_kas version config' do
      version_file = Rails.root.join(described_class::VERSION_FILE)

      expect(described_class.version).to eq(version_file.read.chomp)
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

  describe '.included_in_gitlab_com_rollout?' do
    let_it_be(:project) { create(:project) }

    context 'not GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns true' do
        expect(described_class.included_in_gitlab_com_rollout?(project)).to be_truthy
      end
    end

    context 'GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      context 'kubernetes_agent_on_gitlab_com feature flag disabled' do
        before do
          stub_feature_flags(kubernetes_agent_on_gitlab_com: false)
        end

        it 'returns false' do
          expect(described_class.included_in_gitlab_com_rollout?(project)).to be_falsey
        end
      end

      context 'kubernetes_agent_on_gitlab_com feature flag enabled' do
        before do
          stub_feature_flags(kubernetes_agent_on_gitlab_com: project)
        end

        it 'returns true' do
          expect(described_class.included_in_gitlab_com_rollout?(project)).to be_truthy
        end

        it 'returns false for another project' do
          expect(described_class.included_in_gitlab_com_rollout?(create(:project))).to be_falsey
        end
      end
    end
  end
end
