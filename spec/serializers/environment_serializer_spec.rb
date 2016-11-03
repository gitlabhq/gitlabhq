require 'spec_helper'

describe EnvironmentSerializer do
  let(:serializer) do
    described_class
      .new(user: user, project: project)
      .represent(resource)
  end

  let(:user) { create(:user) }

  context 'when there is a single object provided' do
    let(:deployment) do
      create(:deployment, deployable: deployable,
                          user: user)
    end

    let(:deployable) { create(:ci_build) }
    let(:project) { deployment.project }
    let(:resource) { deployment.environment }

    it 'shows json' do
      pp serializer.as_json
    end

    it 'it generates payload for single object' do
      expect(serializer.as_json).to be_an_instance_of Hash
    end
  end

  context 'when there is a collection of objects provided' do
    let(:project) { create(:empty_project) }
    let(:resource) { create_list(:environment, 2) }

    it 'shows json' do
      puts serializer.as_json
    end

    it 'generates payload for collection' do
      expect(serializer.as_json).to be_an_instance_of Array
    end
  end
end
