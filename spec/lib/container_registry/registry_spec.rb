# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Registry do
  let(:path) { nil }
  let(:registry_api_url) { 'http://example.com' }
  let(:registry) { described_class.new(registry_api_url, path: path) }

  subject { registry }

  before do
    stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
  end

  it { is_expected.to respond_to(:client) }
  it { is_expected.to respond_to(:uri) }
  it { is_expected.to respond_to(:path) }

  it { expect(subject).not_to be_nil }

  describe '#path' do
    subject { registry.path }

    context 'path from URL' do
      it { is_expected.to eq('example.com') }
    end

    context 'custom path' do
      let(:path) { 'registry.example.com' }

      it { is_expected.to eq(path) }
    end
  end

  describe '#gitlab_api_client' do
    subject { registry.gitlab_api_client }

    it 'returns a GitLabApiClient' do
      expect(subject).to be_instance_of(ContainerRegistry::GitlabApiClient)
    end
  end
end
