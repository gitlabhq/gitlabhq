require 'spec_helper'

describe GeoRepositoryFetchWorker do
  describe '#perform' do
    let(:project) { create(:empty_project) }

    before do
      allow_any_instance_of(Gitlab::Geo).to receive_messages(secondary?: true)
      allow_any_instance_of(Repository).to receive(:fetch_geo_mirror).and_return(true)
      allow_any_instance_of(Project).to receive(:repository_exists?) { false }
      allow_any_instance_of(Project).to receive(:empty_repo?) { true }
    end

    it 'creates a new repository' do
      expect_any_instance_of(Project).to receive(:create_repository)

      perform
    end

    it 'executes after_create hook' do
      expect_any_instance_of(Repository).to receive(:after_create).at_least(:once)

      perform
    end

    it 'fetches the Geo mirror' do
      expect_any_instance_of(Repository).to receive(:fetch_geo_mirror)

      perform
    end
  end

  def perform
    subject.perform(project.id, project.ssh_url_to_repo)
  end
end
