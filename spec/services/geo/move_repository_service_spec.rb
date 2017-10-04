require 'spec_helper'

describe Geo::MoveRepositoryService do
  let(:project) { create(:project, :repository) }
  let(:new_path) { "#{project.full_path}+renamed" }

  describe '#execute' do
    it 'moves project backed by legacy storage' do
      old_path = project.repository.path_to_repo
      full_new_path = File.join(project.repository_storage_path, new_path)

      service = described_class.new(project.id, project.full_path, new_path)

      expect(File.directory?(old_path)).to be_truthy
      expect(service.execute).to eq(true)
      expect(File.directory?(old_path)).to be_falsey
      expect(File.directory?("#{full_new_path}.git")).to be_truthy
    end

    it 'does not move project backed by hashed storage' do
      project_hashed_storage = create(:project, :hashed)
      gitlab_shell = Gitlab::Shell.new

      service = described_class.new(project_hashed_storage.id, project_hashed_storage.full_path, new_path)

      allow(service).to receive(:gitlab_shell).and_return(gitlab_shell)

      expect(service.execute).to eq(true)
      expect(gitlab_shell).not_to receive(:mv_repository)
    end
  end

  describe '#async_execute' do
    subject(:service) { described_class.new(project.id, project.full_path, new_path) }

    it 'starts the worker' do
      expect(GeoRepositoryMoveWorker).to receive(:perform_async)

      service.async_execute
    end

    it 'returns job id' do
      allow(GeoRepositoryMoveWorker).to receive(:perform_async).and_return('foo')

      expect(service.async_execute).to eq('foo')
    end
  end
end
