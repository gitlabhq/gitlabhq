# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::RepositoryImporter, feature_category: :importers do
  let(:repository) { double(:repository) }
  let(:import_state) { double(:import_state) }
  let(:client) { double(:client) }

  let(:wiki) do
    double(
      :wiki,
      disk_path: 'foo.wiki',
      full_path: 'group/foo.wiki',
      repository: wiki_repository
    )
  end

  let(:wiki_repository) do
    double(:wiki_repository)
  end

  let(:project) do
    double(
      :project,
      id: 1,
      unsafe_import_url: 'foo.git',
      import_source: 'foo/bar',
      repository_storage: 'foo',
      disk_path: 'foo',
      repository: repository,
      create_wiki: true,
      import_state: import_state,
      full_path: 'group/foo',
      lfs_enabled?: true,
      wiki: wiki
    )
  end

  let(:importer) { described_class.new(project, client) }
  let(:shell_adapter) { Gitlab::Shell.new }

  before do
    # The method "gitlab_shell" returns a new instance every call, making
    # it harder to set expectations. To work around this we'll stub the method
    # and return the same instance on every call.
    allow(importer).to receive(:gitlab_shell).and_return(shell_adapter)
  end

  describe '#import_wiki?' do
    it 'returns true if the wiki should be imported' do
      repo = { has_wiki: true }

      expect(client)
        .to receive(:repository)
        .with('foo/bar')
        .and_return(repo)

      expect(project)
        .to receive(:wiki_repository_exists?)
        .and_return(false)

      expect(importer.import_wiki?).to be(true)
    end

    it 'returns false if the GitHub wiki is disabled' do
      repo = { has_wiki: false }

      expect(client)
        .to receive(:repository)
        .with('foo/bar')
        .and_return(repo)

      expect(importer.import_wiki?).to eq(false)
    end

    it 'returns false if the wiki has already been imported' do
      repo = { has_wiki: true }

      expect(client)
        .to receive(:repository)
        .with('foo/bar')
        .and_return(repo)

      expect(project)
        .to receive(:wiki_repository_exists?)
        .and_return(true)

      expect(importer.import_wiki?).to eq(false)
    end
  end

  describe '#execute' do
    it 'imports the repository and wiki' do
      expect(project)
        .to receive(:empty_repo?)
        .and_return(true)

      expect(importer)
        .to receive(:import_wiki?)
        .and_return(true)

      expect(importer)
        .to receive(:import_repository)
        .and_return(true)

      expect(importer)
        .to receive(:import_wiki_repository)
        .and_return(true)

      expect(importer)
        .to receive(:update_clone_time)

      expect(importer.execute).to eq(true)
    end

    it 'does not import the repository if it already exists' do
      expect(project)
        .to receive(:empty_repo?)
        .and_return(false)

      expect(importer)
        .to receive(:import_wiki?)
        .and_return(true)

      expect(importer)
        .not_to receive(:import_repository)

      expect(importer)
        .to receive(:import_wiki_repository)
        .and_return(true)

      expect(importer)
        .to receive(:update_clone_time)

      expect(importer.execute).to eq(true)
    end

    it 'does not import the wiki if it is disabled' do
      expect(project)
        .to receive(:empty_repo?)
        .and_return(true)

      expect(importer)
        .to receive(:import_wiki?)
        .and_return(false)

      expect(importer)
        .to receive(:import_repository)
        .and_return(true)

      expect(importer)
        .to receive(:update_clone_time)

      expect(importer)
        .not_to receive(:import_wiki_repository)

      expect(importer.execute).to eq(true)
    end

    it 'does not import the wiki if the repository could not be imported' do
      expect(project)
        .to receive(:empty_repo?)
        .and_return(true)

      expect(importer)
        .to receive(:import_wiki?)
        .and_return(true)

      expect(importer)
        .to receive(:import_repository)
        .and_return(false)

      expect(importer)
        .not_to receive(:update_clone_time)

      expect(importer)
        .not_to receive(:import_wiki_repository)

      expect(importer.execute).to eq(false)
    end
  end

  shared_examples 'passes resolved_address for DNS rebinding protection' do
    context 'when URL validation raises BlockedUrlError' do
      before do
        allow(importer).to receive(:get_resolved_address)
          .and_raise(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError, 'Requests to localhost are not allowed')
      end

      it 'propagates the error' do
        expect { perform_import }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end
  end

  describe '#import_repository' do
    before do
      allow(importer).to receive(:get_resolved_address).and_return('')
    end

    let(:perform_import) do
      allow(project).to receive(:ensure_repository)
      importer.import_repository
    end

    it 'imports the repository with resolved_address' do
      repo = { default_branch: 'develop' }

      expect(client)
        .to receive(:repository)
        .with('foo/bar')
        .and_return(repo)

      expect(project)
        .to receive(:change_head)
        .with('develop')

      expect(project)
        .to receive(:ensure_repository)

      expect(repository)
        .to receive(:fetch_as_mirror)
        .with(project.unsafe_import_url, refmap: Gitlab::GithubImport.refmap, forced: true, resolved_address: '')

      expect(importer).to receive(:validate_repository_size!)

      service = double
      expect(::Repositories::HousekeepingService)
        .to receive(:new).with(project, :gc).and_return(service)
      expect(service).to receive(:execute)

      expect(importer.import_repository).to eq(true)
    end

    context 'when DNS rebinding protection resolves to a different IP' do
      before do
        allow(importer).to receive(:get_resolved_address).and_return('93.184.216.34')
        allow(client).to receive(:repository).with('foo/bar').and_return({ default_branch: 'develop' })
        allow(project).to receive(:change_head)
        allow(project).to receive(:ensure_repository)
        allow(importer).to receive(:validate_repository_size!)
        allow(::Repositories::HousekeepingService).to receive_message_chain(:new, :execute)
      end

      it 'passes the resolved address to fetch_as_mirror' do
        expect(repository)
          .to receive(:fetch_as_mirror)
          .with(project.unsafe_import_url, refmap: Gitlab::GithubImport.refmap,
            forced: true, resolved_address: '93.184.216.34')

        importer.import_repository
      end
    end

    it_behaves_like 'passes resolved_address for DNS rebinding protection'
  end

  describe '#import_wiki_repository' do
    before do
      allow(importer).to receive(:get_resolved_address).and_return('')
    end

    let(:perform_import) { importer.import_wiki_repository }

    it 'imports the wiki repository with resolved_address' do
      expect(wiki_repository)
        .to receive(:import_repository)
        .with(importer.wiki_url, resolved_address: '')
        .and_return(true)

      expect(importer.import_wiki_repository).to eq(true)
    end

    context 'when DNS rebinding protection resolves to a different IP' do
      before do
        allow(importer).to receive(:get_resolved_address).and_return('93.184.216.34')
      end

      it 'passes the resolved address to import_repository' do
        expect(wiki_repository)
          .to receive(:import_repository)
          .with(importer.wiki_url, resolved_address: '93.184.216.34')
          .and_return(true)

        expect(importer.import_wiki_repository).to be(true)
      end
    end

    it_behaves_like 'passes resolved_address for DNS rebinding protection'

    context 'when it raises a Gitlab::Git::CommandError' do
      context 'when the error is not a "repository not exported"' do
        it 'creates the wiki and re-raise the exception' do
          exception = Gitlab::Git::CommandError.new

          expect(wiki_repository)
            .to receive(:import_repository)
            .with(importer.wiki_url, resolved_address: '')
            .and_raise(exception)

          expect(project)
            .to receive(:create_wiki)

          expect { importer.import_wiki_repository }
            .to raise_error(exception)
        end
      end

      context 'when the error is a "repository not exported"' do
        it 'returns true' do
          exception = Gitlab::Git::CommandError.new('repository not exported')

          expect(wiki_repository)
            .to receive(:import_repository)
            .with(importer.wiki_url, resolved_address: '')
            .and_raise(exception)

          expect(project)
            .not_to receive(:create_wiki)

          expect(importer.import_wiki_repository)
            .to eq(true)
        end
      end
    end

    context 'when it raises a Gitlab::Git::Repository::NoRepository' do
      context 'when the error is "repository at given URL not found"' do
        it 'returns true' do
          exception = Gitlab::Git::Repository::NoRepository.new(
            'creating repository: cloning repository: repository at given URL not found'
          )

          expect(wiki_repository)
            .to receive(:import_repository)
            .with(importer.wiki_url, resolved_address: '')
            .and_raise(exception)

          expect(project)
            .not_to receive(:create_wiki)

          expect(importer.import_wiki_repository).to be(true)
        end
      end

      context 'when the error message is unrecognised' do
        it 'creates the wiki and re-raises the exception' do
          exception = Gitlab::Git::Repository::NoRepository.new('something else')

          expect(wiki_repository)
            .to receive(:import_repository)
            .with(importer.wiki_url, resolved_address: '')
            .and_raise(exception)

          expect(project)
            .to receive(:create_wiki)

          expect { importer.import_wiki_repository }.to raise_error(exception)
        end
      end
    end
  end

  describe '#update_clone_time' do
    it 'sets the timestamp for when the cloning process finished' do
      freeze_time do
        expect(project)
          .to receive(:touch)
          .with(:last_repository_updated_at)

        importer.update_clone_time
      end
    end
  end

  describe '#get_resolved_address' do
    let(:url) { 'https://example.com/foo.git' }

    subject(:resolved_address) { importer.send(:get_resolved_address, url) }

    before do
      allow(Gitlab::CurrentSettings).to receive_messages(
        allow_local_requests_from_web_hooks_and_services?: false,
        dns_rebinding_protection_enabled?: true,
        deny_all_requests_except_allowed?: false,
        outbound_local_requests_whitelist: []
      )
    end

    context 'when the resolved host is present and the scheme is http(s)' do
      it 'returns the validated hostname' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('https://example.com/foo.git'), '93.184.216.34'])

        expect(resolved_address).to eq('example.com')
      end
    end

    context 'when the resolved host is blank' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('https://example.com/foo.git'), nil])

        expect(resolved_address).to eq('')
      end
    end

    context 'when the scheme is not http(s)' do
      it 'returns an empty string' do
        allow(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!)
          .and_return([URI('ssh://example.com/foo.git'), '93.184.216.34'])

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
