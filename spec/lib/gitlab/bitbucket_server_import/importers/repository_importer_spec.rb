# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::RepositoryImporter, feature_category: :importers do
  include StubRequests

  let_it_be_with_reload(:project) { create(:project, import_url: 'http://bitbucket:test@my-bitbucket') }

  subject(:importer) { described_class.new(project) }

  before do
    stub_dns(project.import_url, ip_address: '8.8.8.9')
  end

  describe '#execute' do
    context 'when repository is empty' do
      it 'imports the repository with the validated resolved address' do
        expect(project.repository).to receive(:import_repository).with(project.unsafe_import_url,
          resolved_address: '8.8.8.9')
        expect(project.last_repository_updated_at).to be_present

        importer.execute
      end
    end

    context 'when repository is not empty' do
      before do
        allow(project).to receive(:empty_repo?).and_return(false)

        project.last_repository_updated_at = 1.day.ago
      end

      it 'does not import the repository' do
        expect(project.repository).not_to receive(:import_repository)

        expect { importer.execute }.not_to change { project.last_repository_updated_at }
      end
    end

    context 'when a Git CommandError is raised and the repository exists' do
      before do
        allow(project.repository).to receive(:import_repository).and_raise(::Gitlab::Git::CommandError)
        allow(project).to receive(:repository_exists?).and_return(true)
      end

      it 'expires repository caches' do
        expect(project.repository).to receive(:expire_content_cache)

        expect { importer.execute }.to raise_error(::Gitlab::Git::CommandError)
      end
    end
  end

  describe '#get_resolved_address' do
    let(:url) { 'http://my-bitbucket/repo.git' }

    subject(:resolved_address) { importer.send(:get_resolved_address, url) }

    context 'when the resolved host is present and the scheme is http(s)' do
      it 'returns the validated hostname' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('http://my-bitbucket/repo.git'), '8.8.8.9'])

        expect(resolved_address).to eq('my-bitbucket')
      end
    end

    context 'when the resolved host is blank' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('http://my-bitbucket/repo.git'), nil])

        expect(resolved_address).to eq('')
      end
    end

    context 'when the scheme is not http(s)' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('ssh://my-bitbucket/repo.git'), '8.8.8.9'])

        expect(resolved_address).to eq('')
      end
    end
  end

  describe '#dns_rebind_protection?' do
    subject(:dns_rebind_protection) { importer.send(:dns_rebind_protection?) }

    context 'when an http proxy is configured' do
      it 'returns false' do
        allow(Gitlab).to receive(:http_proxy_env?).and_return(true)

        expect(dns_rebind_protection).to be(false)
      end
    end

    context 'when no http proxy is configured' do
      it 'returns the current setting' do
        allow(Gitlab).to receive(:http_proxy_env?).and_return(false)
        allow(Gitlab::CurrentSettings).to receive(:dns_rebinding_protection_enabled?).and_return(true)

        expect(dns_rebind_protection).to be(true)
      end
    end
  end
end
