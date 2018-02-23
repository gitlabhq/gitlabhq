require 'spec_helper'

describe Gitlab::GithubImport::Importer::RepositoryImporter do
  let(:repository) { double(:repository) }
  let(:client) { double(:client) }

  let(:project) do
    double(
      :project,
      import_url: 'foo.git',
      import_source: 'foo/bar',
      repository_storage_path: 'foo',
      disk_path: 'foo',
      repository: repository,
      create_wiki: true
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
      repo = double(:repo, has_wiki: true)

      expect(client)
        .to receive(:repository)
        .with('foo/bar')
        .and_return(repo)

      expect(project)
        .to receive(:wiki_repository_exists?)
        .and_return(false)

      expect(importer.import_wiki?).to eq(true)
    end

    it 'returns false if the GitHub wiki is disabled' do
      repo = double(:repo, has_wiki: false)

      expect(client)
        .to receive(:repository)
        .with('foo/bar')
        .and_return(repo)

      expect(importer.import_wiki?).to eq(false)
    end

    it 'returns false if the wiki has already been imported' do
      repo = double(:repo, has_wiki: true)

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
      expect(project)
        .to receive(:ensure_repository)

      expect(repository)
        .to receive(:fetch_as_mirror)
        .with(project.import_url, refmap: Gitlab::GithubImport.refmap, forced: true, remote_name: 'github')

      expect(importer.import_repository).to eq(true)
    end

    it 'marks the import as failed when an error was raised' do
      expect(project).to receive(:ensure_repository)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      expect(importer)
        .to receive(:fail_import)
        .and_return(false)

      expect(importer.import_repository).to eq(false)
    end
  end

  describe '#import_wiki_repository' do
    it 'imports the wiki repository' do
      expect(importer.gitlab_shell)
        .to receive(:import_repository)
        .with('foo', 'foo.wiki', 'foo.wiki.git')

      expect(importer.import_wiki_repository).to eq(true)
    end

    it 'marks the import as failed and creates an empty repo if an error was raised' do
      expect(importer.gitlab_shell)
        .to receive(:import_repository)
        .and_raise(Gitlab::Shell::Error)

      expect(importer)
        .to receive(:fail_import)
        .and_return(false)

      expect(project)
        .to receive(:create_wiki)

      expect(importer.import_wiki_repository).to eq(false)
    end
  end

  describe '#fail_import' do
    it 'marks the import as failed' do
      expect(project).to receive(:mark_import_as_failed).with('foo')

      expect(importer.fail_import('foo')).to eq(false)
    end
  end

  describe '#update_clone_time' do
    it 'sets the timestamp for when the cloning process finished' do
      Timecop.freeze do
        expect(project)
          .to receive(:update_column)
          .with(:last_repository_updated_at, Time.zone.now)

        importer.update_clone_time
      end
    end
  end
end
