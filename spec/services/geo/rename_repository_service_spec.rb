require 'spec_helper'

describe Geo::RenameRepositoryService do
  let(:project) { create(:project, :repository) }
  let(:new_path) { "#{project.full_path}+renamed" }

  describe '#execute' do
    it 'moves project backed by legacy storage' do
      service = described_class.new(project.id, project.full_path, new_path)

      expect_any_instance_of(Geo::MoveRepositoryService).to receive(:execute).once

      service.execute
    end

    it 'does not move project backed by hashed storage' do
      project_hashed_storage = create(:project, :hashed)
      service = described_class.new(project_hashed_storage.id, project_hashed_storage.full_path, new_path)

      expect_any_instance_of(Geo::MoveRepositoryService).not_to receive(:execute)

      service.execute
    end
  end

  describe '#async_execute' do
    subject(:service) { described_class.new(project.id, project.full_path, new_path) }

    it 'starts the worker' do
      expect(Geo::RenameRepositoryWorker).to receive(:perform_async)

      service.async_execute
    end

    it 'returns job id' do
      allow(Geo::RenameRepositoryWorker).to receive(:perform_async).and_return('foo')

      expect(service.async_execute).to eq('foo')
    end
  end
end
