require 'spec_helper'

describe EnvironmentSerializer do
  let(:serializer) do
    described_class
      .new(user: user, project: project)
      .represent(resource)
  end

  let(:json) { serializer.as_json }
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  context 'when there is a single object provided' do
    before do
      create(:ci_build, :manual, name: 'manual1',
                                 pipeline: deployable.pipeline)
    end

    let(:deployment) do
      create(:deployment, deployable: deployable,
                          user: user,
                          project: project,
                          sha: project.commit.id)
    end

    let(:deployable) { create(:ci_build) }
    let(:resource) { deployment.environment }

    it 'contains important elements of environment' do
      expect(json)
        .to include(:name, :external_url, :environment_path, :last_deployment)
    end

    it 'contains relevant information about last deployment' do
      last_deployment = json.fetch(:last_deployment)

      expect(last_deployment)
        .to include(:ref, :user, :commit, :deployable, :manual_actions)
    end
  end

  context 'when there is a collection of objects provided' do
    let(:project) { create(:empty_project) }
    let(:resource) { create_list(:environment, 2) }

    it 'contains important elements of environment' do
      expect(json.first)
        .to include(:last_deployment, :name, :external_url)
    end

    it 'generates payload for collection' do
      expect(json).to be_an_instance_of Array
    end
  end
end
