# frozen_string_literal: true

require 'spec_helper'

describe DeploymentEntity do
  let(:user) { developer }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:project) { create(:project) }
  let(:request) { double('request') }
  let(:deployment) { create(:deployment, deployable: build, project: project) }
  let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
  let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let(:entity) { described_class.new(deployment, request: request) }

  subject { entity.as_json }

  before do
    project.add_developer(developer)
    project.add_reporter(reporter)
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
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

  it 'exposes deployed_at' do
    expect(subject).to include(:deployed_at)
  end

  context 'when deployable is nil' do
    let(:entity) { described_class.new(deployment, request: request, deployment_details: false) }
    let(:deployment) { create(:deployment, deployable: nil, project: project) }

    it 'does not expose deployable entry' do
      expect(subject).not_to include(:deployable)
    end
  end

  context 'when the pipeline has another manual action' do
    let(:other_build) { create(:ci_build, :manual, name: 'another deploy', pipeline: pipeline) }
    let!(:other_deployment) { create(:deployment, deployable: other_build) }

    it 'returns another manual action' do
      expect(subject[:manual_actions].count).to eq(1)
      expect(subject[:manual_actions].first[:name]).to eq('another deploy')
    end

    context 'when user is a reporter' do
      let(:user) { reporter }

      it 'returns another manual action' do
        expect(subject[:manual_actions]).not_to be_present
      end
    end

    context 'when deployment details serialization was disabled' do
      let(:entity) do
        described_class.new(deployment, request: request, deployment_details: false)
      end

      it 'does not serialize manual actions details' do
        expect(subject.with_indifferent_access).not_to include(:manual_actions)
      end
    end
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

    context 'when deployment details serialization was disabled' do
      let(:entity) do
        described_class.new(deployment, request: request, deployment_details: false)
      end

      it 'does not serialize scheduled actions details' do
        expect(subject.with_indifferent_access).not_to include(:scheduled_actions)
      end
    end
  end

  describe 'playable_build' do
    let_it_be(:project) { create(:project, :repository) }

    context 'when the deployment has a playable deployable' do
      context 'when this build is ready to be played' do
        let(:build) { create(:ci_build, :playable, :scheduled, pipeline: pipeline) }

        it 'exposes only the play_path' do
          expect(subject[:playable_build].keys).to contain_exactly(:play_path)
        end
      end

      context 'when this build has failed' do
        let(:build) { create(:ci_build, :playable, :failed, pipeline: pipeline) }

        it 'exposes the play_path and the retry_path' do
          expect(subject[:playable_build].keys).to contain_exactly(:play_path, :retry_path)
        end
      end
    end

    context 'when the deployment does not have a playable deployable' do
      let(:build) { create(:ci_build) }

      it 'is not exposed' do
        expect(subject[:playable_build]).to be_nil
      end
    end
  end

  context 'when deployment details serialization was disabled' do
    include Gitlab::Routing

    let(:entity) do
      described_class.new(deployment, request: request, deployment_details: false)
    end

    it 'does not serialize deployment details' do
      expect(subject.with_indifferent_access)
        .not_to include(:commit, :manual_actions, :scheduled_actions)
    end

    it 'only exposes deployable name and path' do
      project_job_path(project, deployment.deployable).tap do |path|
        expect(subject.fetch(:deployable))
          .to eq(name: 'test', build_path: path)
      end
    end
  end
end
