require 'spec_helper'

describe Projects::UpdateRepositoryStorageService do
  include StubConfiguration

  subject { described_class.new(project) }

  describe "#execute" do
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:time) { Time.now }

    before do
      FileUtils.mkdir('tmp/tests/storage_a')
      FileUtils.mkdir('tmp/tests/storage_b')

      storages = {
        'a' => { 'path' => 'tmp/tests/storage_a' },
        'b' => { 'path' => 'tmp/tests/storage_b' }
      }
      stub_storage_settings(storages)
      allow(subject).to receive(:gitlab_shell).and_return(gitlab_shell)

      allow(Time).to receive(:now).and_return(time)
    end

    after do
      FileUtils.rm_rf('tmp/tests/storage_a')
      FileUtils.rm_rf('tmp/tests/storage_b')
    end

    context 'without wiki', skip_gitaly_mock: true do
      let(:project) { create(:project, :repository, repository_storage: 'a', repository_read_only: true, wiki_enabled: false) }

      context 'when the move succeeds' do
        it 'moves the repository to the new storage and unmarks the repository as read only' do
          expect(gitlab_shell).to receive(:mv_storage)
            .with('tmp/tests/storage_a', project.disk_path, 'tmp/tests/storage_b')
            .and_return(true)
          expect(GitlabShellWorker).to receive(:perform_async)
            .with(:mv_repository,
              'tmp/tests/storage_a',
              project.disk_path,
              "#{project.disk_path}+#{project.id}+moved+#{time.to_i}")

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('b')
        end
      end

      context 'when the move fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          expect(gitlab_shell).to receive(:mv_storage)
            .with('tmp/tests/storage_a', project.disk_path, 'tmp/tests/storage_b')
            .and_return(false)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('a')
        end
      end
    end

    context 'with wiki', skip_gitaly_mock: true do
      let(:project) { create(:project, :repository, repository_storage: 'a', repository_read_only: true, wiki_enabled: true) }

      before do
        project.create_wiki
      end

      context 'when the move succeeds' do
        it 'moves the repository and its wiki to the new storage and unmarks the repository as read only' do
          expect(gitlab_shell).to receive(:mv_storage)
            .with('tmp/tests/storage_a', project.disk_path, 'tmp/tests/storage_b')
            .and_return(true)
          expect(GitlabShellWorker).to receive(:perform_async)
            .with(:mv_repository,
              'tmp/tests/storage_a',
              project.disk_path,
              "#{project.disk_path}+#{project.id}+moved+#{time.to_i}")

          expect(gitlab_shell).to receive(:mv_storage)
            .with('tmp/tests/storage_a', "#{project.disk_path}.wiki", 'tmp/tests/storage_b')
            .and_return(true)
          expect(GitlabShellWorker).to receive(:perform_async)
            .with(:mv_repository,
              'tmp/tests/storage_a',
              "#{project.disk_path}.wiki",
              "#{project.disk_path}+#{project.id}+moved+#{time.to_i}.wiki")

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('b')
        end
      end

      context 'when the move of the wiki fails' do
        it 'unmarks the repository as read-only without updating the repository storage' do
          expect(gitlab_shell).to receive(:mv_storage)
            .with('tmp/tests/storage_a', project.disk_path, 'tmp/tests/storage_b')
            .and_return(true)
          expect(gitlab_shell).to receive(:mv_storage)
            .with('tmp/tests/storage_a', "#{project.disk_path}.wiki", 'tmp/tests/storage_b')
            .and_return(false)
          expect(GitlabShellWorker).not_to receive(:perform_async)

          subject.execute('b')

          expect(project).not_to be_repository_read_only
          expect(project.repository_storage).to eq('a')
        end
      end
    end
  end
end
