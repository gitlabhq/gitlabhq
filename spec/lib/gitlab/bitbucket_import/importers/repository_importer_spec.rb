# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::RepositoryImporter, feature_category: :importers do
  include StubRequests

  let_it_be_with_reload(:project) { create(:project, import_url: 'https://bitbucket.org/vim/vim.git') }

  subject(:importer) { described_class.new(project) }

  before do
    # Resolves both the repository and the wiki URL, which share the same host.
    stub_dns(project.import_url, ip_address: '8.8.8.9')

    # Skip the wiki by default so the repository examples don't attempt a real clone.
    # The wiki contexts below opt back in.
    allow(project.wiki).to receive(:repository_exists?).and_return(true)

    allow_next_instance_of(Bitbucket::Client) do |client|
      allow(client).to receive(:repo).and_return(Bitbucket::Representation::Repo.new(
        { 'mainbranch' => { 'name' => 'develop' } }
      ))
    end
  end

  describe '#execute' do
    context 'when repository is empty' do
      it 'imports the repository with the validated resolved address' do
        expect(project.repository).to receive(:import_repository).with(project.unsafe_import_url,
          resolved_address: '8.8.8.9')
        expect(project.repository).to receive(:fetch_as_mirror).with(project.unsafe_import_url,
          refmap: ['+refs/pull-requests/*/to:refs/merge-requests/*/head'], resolved_address: '8.8.8.9')
        expect(project.last_repository_updated_at).to be_present

        importer.execute
      end

      it 'sets the default branch' do
        allow(project.repository).to receive(:import_repository)
        allow(project.repository).to receive(:fetch_as_mirror)

        expect(project).to receive(:change_head).with('develop')

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

    context 'when wiki import raises a Git CommandError' do
      let(:exception) { ::Gitlab::Git::CommandError.new('remote: Repository not found') }

      before do
        allow(project).to receive(:empty_repo?).and_return(false)
        allow(project.wiki).to receive(:repository_exists?).and_return(false)
        allow(project.wiki.repository).to receive(:import_repository).and_raise(exception)
      end

      it 'logs a warning and completes the import', :aggregate_failures do
        expect(importer).to receive(:log_warn).with(
          hash_including(
            import_stage: 'import_wiki',
            message: 'Wiki import skipped. The Bitbucket Cloud wiki repository is no longer accessible.'
          )
        )

        expect(importer.execute).to be(true)
      end
    end

    context 'when wiki import raises a StandardError' do
      let(:exception) { StandardError.new('unexpected failure') }

      before do
        allow(project).to receive(:empty_repo?).and_return(false)
        allow(project.wiki).to receive(:repository_exists?).and_return(false)
        allow(project.wiki.repository).to receive(:import_repository).and_raise(exception)
      end

      it 'logs the exception and continues the import' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          exception,
          hash_including(import_stage: 'import_repository', message: 'failed to import wiki')
        )

        expect(importer.execute).to be(true)
      end
    end
  end

  describe '#get_resolved_address' do
    let(:url) { 'https://bitbucket.org/vim/vim.git' }

    subject(:resolved_address) { importer.send(:get_resolved_address, url) }

    context 'when the resolved host is present and the scheme is http(s)' do
      it 'returns the validated hostname' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('https://bitbucket.org/vim/vim.git'), '8.8.8.9'])

        expect(resolved_address).to eq('bitbucket.org')
      end
    end

    context 'when the resolved host is blank' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('https://bitbucket.org/vim/vim.git'), nil])

        expect(resolved_address).to eq('')
      end
    end

    context 'when the scheme is not http(s)' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('ssh://bitbucket.org/vim/vim.git'), '8.8.8.9'])

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
