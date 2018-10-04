require 'spec_helper'

describe Gitlab::HashedStorage::Migrator do
  describe '#bulk_schedule' do
    it 'schedules job to StorageMigratorWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.bulk_schedule(1, 5) }.to change(StorageMigratorWorker.jobs, :size).by(1)
      end
    end
  end

  describe '#bulk_migrate' do
    let(:projects) { create_list(:project, 2, :legacy_storage) }
    let(:ids) { projects.map(&:id) }

    it 'enqueue jobs to ProjectMigrateHashedStorageWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.bulk_migrate(ids.min, ids.max) }.to change(ProjectMigrateHashedStorageWorker.jobs, :size).by(2)
      end
    end

    it 'sets projects as read only' do
      allow(ProjectMigrateHashedStorageWorker).to receive(:perform_async).twice
      subject.bulk_migrate(ids.min, ids.max)

      projects.each do |project|
        expect(project.reload.repository_read_only?).to be_truthy
      end
    end

    it 'rescues and log exceptions' do
      allow_any_instance_of(Project).to receive(:migrate_to_hashed_storage!).and_raise(StandardError)
      expect { subject.bulk_migrate(ids.min, ids.max) }.not_to raise_error
    end

    it 'delegates each project in specified range to #migrate' do
      projects.each do |project|
        expect(subject).to receive(:migrate).with(project)
      end

      subject.bulk_migrate(ids.min, ids.max)
    end
  end

  describe '#migrate' do
    let(:project) { create(:project, :legacy_storage, :empty_repo) }

    it 'enqueues job to ProjectMigrateHashedStorageWorker' do
      Sidekiq::Testing.fake! do
        expect { subject.migrate(project) }.to change(ProjectMigrateHashedStorageWorker.jobs, :size).by(1)
      end
    end

    it 'rescues and log exceptions' do
      allow(project).to receive(:migrate_to_hashed_storage!).and_raise(StandardError)

      expect { subject.migrate(project) }.not_to raise_error
    end

    it 'sets project as read only' do
      allow(ProjectMigrateHashedStorageWorker).to receive(:perform_async)
      subject.migrate(project)

      expect(project.reload.repository_read_only?).to be_truthy
    end

    it 'migrate project' do
      perform_enqueued_jobs do
        subject.migrate(project)
      end

      expect(project.reload.hashed_storage?(:attachments)).to be_truthy
    end
  end
end
