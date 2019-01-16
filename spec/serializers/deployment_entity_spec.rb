require 'spec_helper'

describe DeploymentEntity do
  let(:user) { create(:user) }
  let(:request) { double('request') }
  let(:deployment) { create(:deployment) }
  let(:entity) { described_class.new(deployment, request: request) }
  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  it 'exposes internal deployment id' do
    expect(subject).to include(:iid)
  end

  it 'exposes nested information about branch' do
    expect(subject[:ref][:name]).to eq 'master'
  end

  it 'exposes creation date' do
    expect(subject).to include(:created_at)
  end

  describe 'scheduled_actions' do
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }
    let(:deployment) { create(:deployment, deployable: build) }

    context 'when the same pipeline has a scheduled action' do
      let(:other_build) { create(:ci_build, :schedulable, :success, pipeline: pipeline, name: 'other build') }
      let!(:other_deployment) { create(:deployment, deployable: other_build) }

      it 'returns other scheduled actions' do
        expect(subject[:scheduled_actions][0][:name]).to eq 'other build'
      end
    end

    context 'when the same pipeline does not have a scheduled action' do
      it 'does not return other actions' do
        expect(subject[:scheduled_actions]).to be_empty
      end
    end
  end
end
