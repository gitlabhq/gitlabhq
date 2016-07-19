require 'spec_helper'

describe ProjectCacheWorker do
  let(:project) { create(:project) }

  subject { described_class.new }

  describe '#perform' do
    it 'updates project cache data' do
      expect_any_instance_of(Repository).to receive(:size)
      expect_any_instance_of(Repository).to receive(:commit_count)

      expect_any_instance_of(Project).to receive(:update_repository_size)
      expect_any_instance_of(Project).to receive(:update_commit_count)

      subject.perform(project.id)
    end

    it 'handles missing repository data' do
      expect_any_instance_of(Repository).to receive(:exists?).and_return(false)
      expect_any_instance_of(Repository).not_to receive(:size)

      subject.perform(project.id)
    end
  end
end
