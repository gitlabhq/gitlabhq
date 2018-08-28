require 'spec_helper'

describe Backup::Repository do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project, :wiki_repo) }
  subject { described_class.new(progress) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)
    allow(FileUtils).to receive(:mkdir_p).and_return(true)
    allow(FileUtils).to receive(:mv).and_return(true)

    allow_any_instance_of(String).to receive(:color) do |string, _color|
      string
    end

    allow_any_instance_of(described_class).to receive(:progress).and_return(progress)
  end

  describe '#dump' do
    describe 'repo failure' do
      before do
        allow(Gitlab::Popen).to receive(:popen).and_return(['normal output', 0])
      end

      it 'does not raise error' do
        expect { subject.dump }.not_to raise_error
      end
    end
  end

  describe '#restore' do
    let(:timestamp) { Time.utc(2017, 3, 22) }
    let(:temp_dirs) do
      Gitlab.config.repositories.storages.map do |name, storage|
        Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          File.join(storage.legacy_disk_path, '..', 'repositories.old.' + timestamp.to_i.to_s)
        end
      end
    end

    around do |example|
      Timecop.freeze(timestamp) { example.run }
    end

    after do
      temp_dirs.each { |path| FileUtils.rm_rf(path) }
    end

    describe 'command failure' do
      before do
        allow_any_instance_of(Gitlab::Shell).to receive(:create_repository).and_return(false)
      end

      context 'hashed storage' do
        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("[Failed] restoring #{project.full_path} repository")
        end
      end

      context 'legacy storage' do
        let!(:project) { create(:project, :legacy_storage) }

        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("[Failed] restoring #{project.full_path} repository")
        end
      end
    end

    context 'restore custom hooks' do
      let(:project) { create(:project, :repository) }
let(:bundle_path) do
  tmp = Tempfile.new(%w[restore .bundle])
  path = tmp.path
  tmp.close
  project.repository.bundle_to_disk(path)
  path
end

after do
  FileUtils.rm_f(bundle_path)
end

      before do
allow(subject).to receive(:path_to_bundle).and_return(bundle_path)
        allow_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:restore_custom_hooks).and_raise('restore custom hooks failed')
      end

      it 'shows the appropriate error' do
        subject.restore

        progress.rewind
        expect(progress.read).to include('Failed to restore custom hooks')
      end
    end
  end

  describe '#prepare_directories', :seed_helper do
    before do
      allow(FileUtils).to receive(:mkdir_p).and_call_original
      allow(FileUtils).to receive(:mv).and_call_original
    end

    after(:all) do
      ensure_seeds
    end

    it' removes all repositories' do
      # Sanity check: there should be something for us to delete
      expect(list_repositories).to include(File.join(SEED_STORAGE_PATH, TEST_REPO_PATH))

      subject.prepare_directories

      expect(list_repositories).to be_empty
    end

    def list_repositories
      Dir[File.join(SEED_STORAGE_PATH, '*.git')]
    end
  end

  describe '#empty_repo?' do
    context 'for a wiki' do
      let(:wiki) { create(:project_wiki) }

      it 'invalidates the emptiness cache' do
        expect(wiki.repository).to receive(:expire_emptiness_caches).once

        subject.send(:empty_repo?, wiki)
      end

      context 'wiki repo has content' do
        let!(:wiki_page) { create(:wiki_page, wiki: wiki) }

        it 'returns true, regardless of bad cache value' do
          expect(subject.send(:empty_repo?, wiki)).to be(false)
        end
      end

      context 'wiki repo does not have content' do
        it 'returns true, regardless of bad cache value' do
          expect(subject.send(:empty_repo?, wiki)).to be_truthy
        end
      end
    end
  end
end
