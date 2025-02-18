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
      import_url: 'foo.git',
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
      expect(Gitlab::GitalyClient::RemoteService)
        .to receive(:exists?)
        .with("foo.wiki.git")
        .and_return(true)

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

  describe '#import_repository' do
    it 'imports the repository' do
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
        .with(project.import_url, refmap: Gitlab::GithubImport.refmap, forced: true)

      expect(importer).to receive(:validate_repository_size!)

      service = double
      expect(::Repositories::HousekeepingService)
        .to receive(:new).with(project, :gc).and_return(service)
      expect(service).to receive(:execute)

      expect(importer.import_repository).to eq(true)
    end
  end

  describe '#import_wiki_repository' do
    it 'imports the wiki repository' do
      expect(wiki_repository)
        .to receive(:import_repository)
        .with(importer.wiki_url)
        .and_return(true)

      expect(importer.import_wiki_repository).to eq(true)
    end

    context 'when it raises a Gitlab::Git::CommandError' do
      context 'when the error is not a "repository not exported"' do
        it 'creates the wiki and re-raise the exception' do
          exception = Gitlab::Git::CommandError.new

          expect(wiki_repository)
            .to receive(:import_repository)
            .with(importer.wiki_url)
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
            .with(importer.wiki_url)
            .and_raise(exception)

          expect(project)
            .not_to receive(:create_wiki)

          expect(importer.import_wiki_repository)
            .to eq(true)
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
end
