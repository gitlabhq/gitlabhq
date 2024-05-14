# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentEntity do
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:user) { developer }
  let_it_be(:project) { create(:project, :repository, developers: developer, reporters: reporter) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let_it_be_with_reload(:build) { create(:ci_build, :manual, :environment_with_deployment_tier, pipeline: pipeline) }
  let_it_be_with_reload(:bridge) do
    create(:ci_bridge, :manual, :environment_with_deployment_tier, pipeline: pipeline, downstream: project)
  end

  let!(:deployment) { create(:deployment, deployable: job, environment: environment, project: project) }

  let(:request) { double('request') }
  let(:entity) { described_class.new(deployment, request: request) }

  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  shared_examples_for 'exposes fields' do
    it 'exposes fields', :aggregate_failures do
      expect(subject).to include(:iid)
      expect(subject[:ref][:name]).to eq 'master'
      expect(subject).to include(:status)
      expect(subject).to include(:created_at)
      expect(subject).to include(:deployed_at)
      expect(subject).to include(:is_last)
      expect(subject).to include(:tier_in_yaml)
      expect(subject).to include(:web_path)
    end
  end

  context 'when deployable is build job' do
    let(:job) { build }

    it_behaves_like 'exposes fields'
  end

  context 'when deployable is bridge job' do
    let(:job) { bridge }

    it_behaves_like 'exposes fields'
  end

  context 'when deployable is nil' do
    let(:entity) { described_class.new(deployment, request: request, deployment_details: false) }
    let(:job) { nil }

    it 'does not expose deployable entry' do
      expect(subject).not_to include(:deployable)
    end
  end

  context 'when the pipeline has another manual action' do
    let!(:other_job) do
      create(:ci_build, :manual, name: 'another deploy', pipeline: pipeline, environment: job.environment)
    end

    let!(:other_deployment) { create(:deployment, deployable: job, environment: environment) }

    let(:job) { build }

    it 'returns another manual action' do
      expect(subject[:manual_actions].count).to eq(2)
      expect(subject[:manual_actions].pluck(:name)).to match_array(['another deploy', 'bridge'])
    end

    context 'when user is a reporter' do
      let_it_be(:user) { reporter }

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
    let(:job) { create(:ci_build, :success, pipeline: pipeline) }

    context 'when the same pipeline has a scheduled action' do
      let(:other_job) { create(:ci_build, :schedulable, :success, pipeline: pipeline, name: 'other job') }
      let!(:other_deployment) { create(:deployment, deployable: other_job, environment: environment) }

      it 'returns other scheduled actions' do
        expect(subject[:scheduled_actions][0][:name]).to eq 'other job'
      end

      context 'when deployable is bridge job' do
        let(:job) { create(:ci_bridge, :success, pipeline: pipeline) }

        it 'returns nil' do
          expect(subject[:scheduled_actions]).to be_nil
        end
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
    context 'when the deployment has a playable deployable' do
      context 'when this job is build and ready to be played' do
        let(:job) { create(:ci_build, :playable, :scheduled, pipeline: pipeline) }

        it 'exposes only the play_path' do
          expect(subject[:playable_build].keys).to contain_exactly(:play_path)
        end
      end

      context 'when this job is bridge and ready to be played' do
        let(:job) { create(:ci_bridge, :playable, :manual, pipeline: pipeline, downstream: project) }

        it 'exposes only the play_path' do
          expect(subject[:playable_build].keys).to contain_exactly(:play_path)
        end
      end

      context 'when this job has failed' do
        let(:job) { create(:ci_build, :playable, :failed, pipeline: pipeline) }

        it 'exposes the play_path and the retry_path' do
          expect(subject[:playable_build].keys).to contain_exactly(:play_path, :retry_path)
        end
      end
    end

    context 'when the deployment does not have a playable deployable' do
      let(:job) { create(:ci_build, pipeline: pipeline) }

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

    let(:job) { build }

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

    context 'when deployable is bridge' do
      let(:job) { bridge }

      it 'only exposes deployable name and path' do
        project_job_path(project, deployment.deployable).tap do |path|
          expect(subject.fetch(:deployable))
            .to eq(name: 'bridge', build_path: path)
        end
      end
    end
  end
end
