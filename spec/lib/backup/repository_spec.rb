require 'spec_helper'

describe Backup::Repository do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project) }

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
        expect { described_class.new.dump }.not_to raise_error
      end
    end
  end

  describe '#restore' do
    subject { described_class.new }

    let(:timestamp) { Time.utc(2017, 3, 22) }
    let(:temp_dirs) do
      Gitlab.config.repositories.storages.map do |name, storage|
        File.join(storage.legacy_disk_path, '..', 'repositories.old.' + timestamp.to_i.to_s)
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
        allow(Gitlab::Popen).to receive(:popen).and_return(['error', 1])
      end

      context 'hashed storage' do
        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} (#{project.disk_path}) - error")
        end
      end

      context 'legacy storage' do
        let!(:project) { create(:project, :legacy_storage) }

        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("Ignoring error on #{project.full_path} - error")
        end
      end
    end

    describe 'folders without permissions' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EACCES)
      end

      it 'shows error message' do
        expect(subject).to receive(:access_denied_error)
        subject.restore
      end
    end

    describe 'folder that is a mountpoint' do
      before do
        allow(FileUtils).to receive(:mv).and_raise(Errno::EBUSY)
      end

      it 'shows error message' do
        expect(subject).to receive(:resource_busy_error).and_call_original

        expect { subject.restore }.to raise_error(/is a mountpoint/)
      end
    end
  end

  describe '#empty_repo?' do
    context 'for a wiki' do
      let(:wiki) { create(:project_wiki) }

      it 'invalidates the emptiness cache' do
        expect(wiki.repository).to receive(:expire_emptiness_caches).once

        wiki.empty?
      end

      context 'wiki repo has content' do
        let!(:wiki_page) { create(:wiki_page, wiki: wiki) }

        it 'returns true, regardless of bad cache value' do
          expect(described_class.new.send(:empty_repo?, wiki)).to be(false)
        end
      end

      context 'wiki repo does not have content' do
        it 'returns true, regardless of bad cache value' do
          expect(described_class.new.send(:empty_repo?, wiki)).to be_truthy
        end
      end
    end
  end
end
