# frozen_string_literal: true

require 'spec_helper'

describe Backup::Repository do
  let(:progress) { StringIO.new }
  let!(:project) { create(:project, :wiki_repo) }

  subject { described_class.new(progress) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)
    allow(FileUtils).to receive(:mv).and_return(true)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:progress).and_return(progress)
    end
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
        allow_next_instance_of(Gitlab::Shell) do |instance|
          allow(instance).to receive(:create_repository).and_return(false)
        end
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

    context 'restoring object pools' do
      it 'schedules restoring of the pool', :sidekiq_might_not_need_inline do
        pool_repository = create(:pool_repository, :failed)
        pool_repository.delete_object_pool

        subject.restore

        pool_repository.reload
        expect(pool_repository).not_to be_failed
        expect(pool_repository.object_pool.exists?).to be(true)
      end
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
