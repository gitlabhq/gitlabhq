require 'spec_helper'

describe Geo::HashedStorageMigrationService do
  let(:project) { create(:project, :repository, :hashed) }
  let(:new_path) { "#{project.full_path}+renamed" }

  describe '#execute' do
    it 'moves project backed by legacy storage' do
      service = described_class.new(
        project.id,
        old_disk_path: project.full_path,
        new_disk_path: new_path,
        old_storage_version: nil
      )

      expect_any_instance_of(Geo::MoveRepositoryService).to receive(:execute).once

      service.execute
    end

    it 'does not move project backed by hashed storage' do
      service = described_class.new(
        project.id,
        old_disk_path: project.full_path,
        new_disk_path: "#{project.full_path}+renamed",
        old_storage_version: project.storage_version
      )

      expect_any_instance_of(Geo::MoveRepositoryService).not_to receive(:execute).once

      service.execute
    end
  end

  describe '#async_execute' do
    subject(:service) { described_class.new(project.id, old_disk_path: project.full_path, new_disk_path: new_path, old_storage_version: nil) }

    it 'starts the worker' do
      expect(Geo::HashedStorageMigrationWorker).to receive(:perform_async)

      service.async_execute
    end

    it 'returns job id' do
      allow(Geo::HashedStorageMigrationWorker).to receive(:perform_async).and_return('foo')

      expect(service.async_execute).to eq('foo')
    end
  end
end
