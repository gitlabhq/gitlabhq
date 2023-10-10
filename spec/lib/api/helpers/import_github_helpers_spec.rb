# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::ImportGithubHelpers, feature_category: :importers do
  subject do
    helper = Class.new.include(described_class).new
    def helper.params = {
      personal_access_token: 'foo',
      additional_access_tokens: 'bar',
      github_hostname: 'github.example.com'
    }
    helper
  end

  describe '#client' do
    context 'when remove_legacy_github_client is enabled' do
      before do
        stub_feature_flags(remove_legacy_github_client: true)
      end

      it 'returns the new github client' do
        expect(subject.client).to be_a(Gitlab::GithubImport::Client)
      end
    end

    context 'when remove_legacy_github_client is disabled' do
      before do
        stub_feature_flags(remove_legacy_github_client: false)
      end

      it 'returns the old github client' do
        expect(subject.client).to be_a(Gitlab::LegacyGithubImport::Client)
      end
    end
  end

  describe '#access_params' do
    it 'makes the passed in personal access token and extra tokens accessible' do
      expect(subject.access_params).to eq({ github_access_token: 'foo', additional_access_tokens: 'bar' })
    end
  end

  describe '#client_options' do
    it 'makes the GitHub hostname accessible' do
      expect(subject.client_options).to eq({ host: 'github.example.com' })
    end
  end

  describe '#provider' do
    it 'is GitHub' do
      expect(subject.provider).to eq(:github)
    end
  end

  describe '#provider_unauthorized' do
    it 'raises an error' do
      expect(subject).to receive(:error!).with('Access denied to your GitHub account.', 401)
      subject.provider_unauthorized
    end
  end

  describe '#too_many_requests' do
    it 'raises an error' do
      expect(subject).to receive(:error!).with('Too Many Requests', 429)
      subject.too_many_requests
    end
  end
end
