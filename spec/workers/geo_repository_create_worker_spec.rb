require 'spec_helper'

describe GeoRepositoryCreateWorker do
  let(:user) { create :user }
  let(:project) { create :project }
  let(:perform!) { subject.perform(project.id) }

  context 'when no repository' do
    before do
      expect(Project).to receive(:find).at_least(:once).with(project.id) { project }
      expect(project).to receive(:repository_exists?) { false }
    end

    it 'creates the repository' do
      expect(project).to receive(:create_repository)

      perform!
    end
  end
end
