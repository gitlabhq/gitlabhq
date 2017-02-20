require 'spec_helper'

describe GeoRepositoryCreateWorker do
  let(:user) { create :user }
  let(:project) { create :project }
  let(:perform!) { subject.perform(project.id) }

  before { expect(Project).to receive(:find).at_least(:once).with(project.id) { project } }

  context 'when no repository' do
    before { expect(project).to receive(:repository_exists?) { false } }

    it 'creates the repository' do
      expect(project).to receive(:create_repository)

      perform!
    end

    it 'does not create the repository when its being imported' do
      expect(project).to receive(:import?) { true }
      expect(project).not_to receive(:create_repository)

      perform!
    end
  end

  context 'when repository exists' do
    before { expect(project).to receive(:repository_exists?) { true } }

    it 'does not try to create the repository again' do
      expect(project).not_to receive(:create_repository)

      perform!
    end
  end
end
