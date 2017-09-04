require 'spec_helper'

describe GeoRepositoryDestroyWorker do
  let(:project) { create(:project) }

  it 'delegates project removal to Geo::RepositoryDestroyService' do
    expect_any_instance_of(Geo::RepositoryDestroyService).to receive(:execute)

    described_class.new.perform(project.id, project.name, project.path, 'default')
  end
end
