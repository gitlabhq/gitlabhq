# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repository do
  let_it_be(:project) { create(:project, :wiki_repo) }

  let(:progress) { StringIO.new }

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
    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(storage_keys)
    end

    let_it_be(:projects) { create_list(:project, 5, :wiki_repo) + [project] }

    let(:storage_keys) { %w[default test_second_storage] }

    context 'no concurrency' do
      it 'creates the expected number of threads' do
        expect(Thread).not_to receive(:new)

        projects.each do |project|
          expect(subject).to receive(:dump_project).with(project).and_call_original
        end

        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
      end

      describe 'command failure' do
        it 'dump_project raises an error' do
          allow(subject).to receive(:dump_project).and_raise(IOError)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(IOError)
        end

        it 'project query raises an error' do
          allow(Project).to receive(:find_each).and_raise(ActiveRecord::StatementTimeout)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(ActiveRecord::StatementTimeout)
        end
      end
    end

    [4, 10].each do |max_storage_concurrency|
      context "max_storage_concurrency #{max_storage_concurrency}" do
        it 'creates the expected number of threads' do
          expect(Thread).to receive(:new)
            .exactly(storage_keys.length * (max_storage_concurrency + 1)).times
            .and_call_original

          projects.each do |project|
            expect(subject).to receive(:dump_project).with(project).and_call_original
          end

          subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
        end

        it 'creates the expected number of threads with extra max concurrency' do
          expect(Thread).to receive(:new)
            .exactly(storage_keys.length * (max_storage_concurrency + 1)).times
            .and_call_original

          projects.each do |project|
            expect(subject).to receive(:dump_project).with(project).and_call_original
          end

          subject.dump(max_concurrency: 3, max_storage_concurrency: max_storage_concurrency)
        end

        describe 'command failure' do
          it 'dump_project raises an error' do
            allow(subject).to receive(:dump_project)
              .and_raise(IOError)

            expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(IOError)
          end

          it 'project query raises an error' do
            allow(Project).to receive_message_chain('for_repository_storage.find_each').and_raise(ActiveRecord::StatementTimeout)

            expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(ActiveRecord::StatementTimeout)
          end

          context 'misconfigured storages' do
            let(:storage_keys) { %w[test_second_storage] }

            it 'raises an error' do
              expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(Backup::Error, 'repositories.storages in gitlab.yml is misconfigured')
            end
          end
        end
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
        # Allow us to set expectations on the project directly
        expect(Project).to receive(:find_each).and_yield(project)
        expect(project.repository).to receive(:create_repository) { raise 'Fail in tests' }
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

    it 'cleans existing repositories' do
      wiki_repository_spy = spy(:wiki)

      allow_next_instance_of(ProjectWiki) do |project_wiki|
        allow(project_wiki).to receive(:repository).and_return(wiki_repository_spy)
      end

      expect_next_instance_of(Repository) do |repo|
        expect(repo).to receive(:remove)
      end

      subject.restore

      expect(wiki_repository_spy).to have_received(:remove)
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
