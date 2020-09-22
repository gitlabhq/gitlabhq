# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Repositories do
  let(:progress) { StringIO.new }

  subject { described_class.new(progress) }

  before do
    allow(progress).to receive(:puts)
    allow(progress).to receive(:print)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:progress).and_return(progress)
    end
  end

  describe '#dump' do
    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(storage_keys)
    end

    let_it_be(:projects) { create_list(:project, 5, :repository, :wiki_repo) }

    let(:storage_keys) { %w[default test_second_storage] }

    context 'no concurrency' do
      it 'creates repository bundle' do
        subject.dump(max_concurrency: 1, max_storage_concurrency: 1)

        projects.each do |project|
          expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.bundle'))
        end
      end

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
          allow(Project).to receive_message_chain(:includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

          expect { subject.dump(max_concurrency: 1, max_storage_concurrency: 1) }.to raise_error(ActiveRecord::StatementTimeout)
        end
      end

      it 'avoids N+1 database queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
        end.count

        create_list(:project, 2, :repository, :wiki_repo)

        expect do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)
        end.not_to exceed_query_limit(control_count)
      end

      context 'legacy storage' do
        let_it_be(:project) { create(:project, :repository, :legacy_storage, :wiki_repo) }

        it 'creates repository bundle' do
          subject.dump(max_concurrency: 1, max_storage_concurrency: 1)

          expect(File).to exist(File.join(Gitlab.config.backup.path, 'repositories', project.disk_path + '.bundle'))
        end
      end
    end

    [4, 10].each do |max_storage_concurrency|
      context "max_storage_concurrency #{max_storage_concurrency}", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/241701' do
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
            allow(Project).to receive_message_chain(:for_repository_storage, :includes, :find_each).and_raise(ActiveRecord::StatementTimeout)

            expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(ActiveRecord::StatementTimeout)
          end

          context 'misconfigured storages' do
            let(:storage_keys) { %w[test_second_storage] }

            it 'raises an error' do
              expect { subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency) }.to raise_error(Backup::Error, 'repositories.storages in gitlab.yml is misconfigured')
            end
          end
        end

        it 'avoids N+1 database queries' do
          control_count = ActiveRecord::QueryRecorder.new do
            subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
          end.count

          create_list(:project, 2, :repository, :wiki_repo)

          expect do
            subject.dump(max_concurrency: 1, max_storage_concurrency: max_storage_concurrency)
          end.not_to exceed_query_limit(control_count)
        end
      end
    end
  end

  describe '#restore' do
    let_it_be(:project) { create(:project, :wiki_repo) }

    describe 'command failure' do
      before do
        expect(Project).to receive(:find_each).and_yield(project)

        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:create_repository) { raise 'Fail in tests' }
        end
      end

      context 'hashed storage' do
        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("[Failed] restoring #{project.full_path} (#{project.disk_path})")
        end
      end

      context 'legacy storage' do
        let_it_be(:project) { create(:project, :legacy_storage) }

        it 'shows the appropriate error' do
          subject.restore

          expect(progress).to have_received(:puts).with("[Failed] restoring #{project.full_path} (#{project.disk_path})")
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
      expect(Repository).to receive(:new).twice.and_wrap_original do |method, *original_args|
        repository = method.call(*original_args)

        expect(repository).to receive(:remove)

        repository
      end

      subject.restore
    end
  end
end
