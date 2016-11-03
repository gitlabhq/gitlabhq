require 'spec_helper'

describe EnvironmentSerializer do
  let(:serializer) do
    described_class
      .new(user: user, project: project)
      .represent(resource)
  end

  let(:user) { create(:user) }

  context 'when there is a single object provided' do
    before do
      create(:ci_build, :manual, name: 'manual1',
                                 pipeline: deployable.pipeline)
    end

    let(:deployment) do
      create(:deployment, deployable: deployable,
                          user: user)
    end

    let(:deployable) { create(:ci_build) }
    let(:project) { deployment.project }
    let(:resource) { deployment.environment }

    it 'it generates payload for single object' do
      expect(serializer.as_json).to be_an_instance_of Hash
    end

    it 'contains important elements of environment' do
      expect(serializer.as_json)
        .to include(:name, :external_url, :environment_url, :last_deployment)
    end

    it 'contains relevant information about last deployment' do
      last_deployment = serializer.as_json.fetch(:last_deployment)

      expect(last_deployment)
        .to include(:ref, :user, :commit, :deployable, :manual_actions)
    end
  end

  context 'when there is a collection of objects provided' do
    let(:project) { create(:empty_project) }
    let(:resource) { create_list(:environment, 2) }

    it 'contains important elements of environment' do
      expect(serializer.as_json.first)
        .to include(:last_deployment, :name, :external_url)
    end

    it 'generates payload for collection' do
      expect(serializer.as_json).to be_an_instance_of Array
    end
  end
end
