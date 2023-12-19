# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::ImportGithubHelpers, feature_category: :importers do
  subject do
    helper = Class.new.include(described_class).new
    def helper.params = {
      personal_access_token: 'foo',
      github_hostname: 'github.example.com'
    }
    helper
  end

  describe '#client' do
    it 'returns the new github client' do
      expect(subject.client).to be_a(Gitlab::GithubImport::Client)
    end
  end

  describe '#access_params' do
    it 'makes the passed in personal access token and extra tokens accessible' do
      expect(subject.access_params).to eq({ github_access_token: 'foo' })
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
