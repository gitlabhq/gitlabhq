# frozen_string_literal: true

require 'spec_helper'

describe Projects::CleanupService do
  let(:project) { create(:project, :repository, bfg_object_map: fixture_file_upload('spec/fixtures/bfg_object_map.txt')) }
  let(:object_map) { project.bfg_object_map }

  subject(:service) { described_class.new(project) }

  describe '#execute' do
    it 'runs the apply_bfg_object_map gitaly RPC' do
      expect_next_instance_of(Gitlab::Git::RepositoryCleaner) do |cleaner|
        expect(cleaner).to receive(:apply_bfg_object_map).with(kind_of(IO))
      end

      service.execute
    end

    it 'runs garbage collection on the repository' do
      expect_next_instance_of(GitGarbageCollectWorker) do |worker|
        expect(worker).to receive(:perform)
      end

      service.execute
    end

    it 'clears the repository cache' do
      expect(project.repository).to receive(:expire_all_method_caches)

      service.execute
    end

    it 'removes the object map file' do
      service.execute

      expect(object_map.exists?).to be_falsy
    end

    it 'raises an error if no object map can be found' do
      object_map.remove!

      expect { service.execute }.to raise_error(described_class::NoUploadError)
    end
  end
end
