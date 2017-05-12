require 'spec_helper'

describe GeoRepositoryFetchWorker do
  describe '#perform' do
    let(:project) { create(:empty_project) }

    it 'delegates to Geo::RepositoryUpdateService' do
      expect_any_instance_of(Geo::RepositoryUpdateService).to receive(:execute)

      perform
    end
  end

  def perform
    subject.perform(project.id, project.ssh_url_to_repo)
  end
end
