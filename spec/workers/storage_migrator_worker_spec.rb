require 'spec_helper'

describe StorageMigratorWorker do
  subject(:worker) { described_class.new }
  let(:projects) { create_list(:project, 2, :legacy_storage) }

  describe '#perform' do
    let(:ids) { projects.map(&:id) }

    it 'enqueue jobs to ProjectMigrateHashedStorageWorker' do
      expect(ProjectMigrateHashedStorageWorker).to receive(:perform_async).twice

      worker.perform(ids.min, ids.max)
    end

    it 'sets projects as read only' do
      allow(ProjectMigrateHashedStorageWorker).to receive(:perform_async).twice
      worker.perform(ids.min, ids.max)

      projects.each do |project|
        expect(project.reload.repository_read_only?).to be_truthy
      end
    end

    it 'rescues and log exceptions' do
      allow_any_instance_of(Project).to receive(:migrate_to_hashed_storage!).and_raise(StandardError)
      expect { worker.perform(ids.min, ids.max) }.not_to raise_error
    end
  end
end
