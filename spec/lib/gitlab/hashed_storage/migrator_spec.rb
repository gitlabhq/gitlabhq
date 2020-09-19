# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HashedStorage::Migrator, :redis do
  describe '#bulk_schedule_migration' do
    it 'schedules job to HashedStorage::MigratorWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.bulk_schedule_migration(start: 1, finish: 5) }.to change(HashedStorage::MigratorWorker.jobs, :size).by(1)
      end
    end
  end

  describe '#bulk_schedule_rollback' do
    it 'schedules job to HashedStorage::RollbackerWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.bulk_schedule_rollback(start: 1, finish: 5) }.to change(HashedStorage::RollbackerWorker.jobs, :size).by(1)
      end
    end
  end

  describe '#bulk_migrate' do
    let(:projects) { create_list(:project, 2, :legacy_storage, :empty_repo) }
    let(:ids) { projects.map(&:id) }

    it 'enqueue jobs to HashedStorage::ProjectMigrateWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.bulk_migrate(start: ids.min, finish: ids.max) }.to change(HashedStorage::ProjectMigrateWorker.jobs, :size).by(2)
      end
    end

    it 'rescues and log exceptions' do
      allow_any_instance_of(Project).to receive(:migrate_to_hashed_storage!).and_raise(StandardError)
      expect { subject.bulk_migrate(start: ids.min, finish: ids.max) }.not_to raise_error
    end

    it 'delegates each project in specified range to #migrate' do
      projects.each do |project|
        expect(subject).to receive(:migrate).with(project)
      end

      subject.bulk_migrate(start: ids.min, finish: ids.max)
    end

    it 'has all projects migrated and set as writable', :sidekiq_might_not_need_inline do
      perform_enqueued_jobs do
        subject.bulk_migrate(start: ids.min, finish: ids.max)
      end

      projects.each do |project|
        project.reload

        expect(project.hashed_storage?(:repository)).to be_truthy
        expect(project.repository_read_only?).to be_falsey
      end
    end
  end

  describe '#bulk_rollback' do
    let(:projects) { create_list(:project, 2, :empty_repo) }
    let(:ids) { projects.map(&:id) }

    it 'enqueue jobs to HashedStorage::ProjectRollbackWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.bulk_rollback(start: ids.min, finish: ids.max) }.to change(HashedStorage::ProjectRollbackWorker.jobs, :size).by(2)
      end
    end

    it 'rescues and log exceptions' do
      allow_any_instance_of(Project).to receive(:rollback_to_legacy_storage!).and_raise(StandardError)
      expect { subject.bulk_rollback(start: ids.min, finish: ids.max) }.not_to raise_error
    end

    it 'delegates each project in specified range to #rollback' do
      projects.each do |project|
        expect(subject).to receive(:rollback).with(project)
      end

      subject.bulk_rollback(start: ids.min, finish: ids.max)
    end

    it 'has all projects rolledback and set as writable', :sidekiq_might_not_need_inline do
      perform_enqueued_jobs do
        subject.bulk_rollback(start: ids.min, finish: ids.max)
      end

      projects.each do |project|
        project.reload

        expect(project.legacy_storage?).to be_truthy
        expect(project.repository_read_only?).to be_falsey
      end
    end
  end

  describe '#migrate' do
    let(:project) { create(:project, :legacy_storage, :empty_repo) }

    it 'enqueues project migration job' do
      Sidekiq::Testing.fake! do
        expect { subject.migrate(project) }.to change(HashedStorage::ProjectMigrateWorker.jobs, :size).by(1)
      end
    end

    it 'rescues and log exceptions' do
      allow(project).to receive(:migrate_to_hashed_storage!).and_raise(StandardError)

      expect { subject.migrate(project) }.not_to raise_error
    end

    it 'migrates project storage', :sidekiq_might_not_need_inline do
      perform_enqueued_jobs do
        subject.migrate(project)
      end

      expect(project.reload.hashed_storage?(:attachments)).to be_truthy
    end

    it 'has migrated project set as writable' do
      perform_enqueued_jobs do
        subject.migrate(project)
      end

      expect(project.reload.repository_read_only?).to be_falsey
    end

    context 'when project is already on hashed storage' do
      let(:project) { create(:project, :empty_repo) }

      it 'doesnt enqueue any migration job' do
        Sidekiq::Testing.fake! do
          expect { subject.migrate(project) }.not_to change(HashedStorage::ProjectMigrateWorker.jobs, :size)
        end
      end

      it 'returns false' do
        expect(subject.migrate(project)).to be_falsey
      end
    end
  end

  describe '#rollback' do
    let(:project) { create(:project, :empty_repo) }

    it 'enqueues project rollback job' do
      Sidekiq::Testing.fake! do
        expect { subject.rollback(project) }.to change(HashedStorage::ProjectRollbackWorker.jobs, :size).by(1)
      end
    end

    it 'rescues and log exceptions' do
      allow(project).to receive(:rollback_to_hashed_storage!).and_raise(StandardError)

      expect { subject.rollback(project) }.not_to raise_error
    end

    it 'rolls-back project storage', :sidekiq_might_not_need_inline do
      perform_enqueued_jobs do
        subject.rollback(project)
      end

      expect(project.reload.legacy_storage?).to be_truthy
    end

    it 'has rolled-back project set as writable' do
      perform_enqueued_jobs do
        subject.rollback(project)
      end

      expect(project.reload.repository_read_only?).to be_falsey
    end

    context 'when project is already on legacy storage' do
      let(:project) { create(:project, :legacy_storage, :empty_repo) }

      it 'doesnt enqueue any rollback job' do
        Sidekiq::Testing.fake! do
          expect { subject.rollback(project) }.not_to change(HashedStorage::ProjectRollbackWorker.jobs, :size)
        end
      end

      it 'returns false' do
        expect(subject.rollback(project)).to be_falsey
      end
    end
  end

  describe 'migration_pending?' do
    let_it_be(:project) { create(:project, :empty_repo) }

    it 'returns true when there are MigratorWorker jobs scheduled' do
      Sidekiq::Testing.disable! do
        ::HashedStorage::MigratorWorker.perform_async(1, 5)

        expect(subject.migration_pending?).to be_truthy
      end
    end

    it 'returns true when there are ProjectMigrateWorker jobs scheduled' do
      Sidekiq::Testing.disable! do
        ::HashedStorage::ProjectMigrateWorker.perform_async(1)

        expect(subject.migration_pending?).to be_truthy
      end
    end

    it 'returns false when queues are empty' do
      expect(subject.migration_pending?).to be_falsey
    end
  end

  describe 'rollback_pending?' do
    let_it_be(:project) { create(:project, :empty_repo) }

    it 'returns true when there are RollbackerWorker jobs scheduled' do
      Sidekiq::Testing.disable! do
        ::HashedStorage::RollbackerWorker.perform_async(1, 5)

        expect(subject.rollback_pending?).to be_truthy
      end
    end

    it 'returns true when there are jobs scheduled' do
      Sidekiq::Testing.disable! do
        ::HashedStorage::ProjectRollbackWorker.perform_async(1)

        expect(subject.rollback_pending?).to be_truthy
      end
    end

    it 'returns false when queues are empty' do
      expect(subject.rollback_pending?).to be_falsey
    end
  end

  describe 'abort_rollback!' do
    let_it_be(:project) { create(:project, :empty_repo) }

    it 'removes any rollback related scheduled job' do
      Sidekiq::Testing.disable! do
        ::HashedStorage::RollbackerWorker.perform_async(1, 5)

        expect { subject.abort_rollback! }.to change { subject.rollback_pending? }.from(true).to(false)
      end
    end
  end
end
