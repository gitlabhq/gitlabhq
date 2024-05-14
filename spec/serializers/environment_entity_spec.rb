# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentEntity do
  include KubernetesHelpers
  include Gitlab::Routing.url_helpers

  let(:request) { double('request', current_user: user, project: project) }
  let(:entity) do
    described_class.new(environment, request: request)
  end

  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: user) }
  let_it_be(:environment, refind: true) { create(:environment, project: project) }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  subject { entity.as_json }

  it 'exposes latest deployment' do
    expect(subject).to include(:last_deployment)
  end

  it 'exposes core elements of environment' do
    expect(subject).to include(:id, :global_id, :name, :state, :environment_path, :tier)
  end

  it 'exposes folder path' do
    expect(subject).to include(:folder_path)
  end

  context 'when there is a successful deployment' do
    let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
    let!(:deployable) { create(:ci_build, :success, project: project, pipeline: pipeline) }
    let!(:deployment) { create(:deployment, :success, project: project, environment: environment, deployable: deployable) }

    it 'exposes it as the latest deployment' do
      expect(subject[:last_deployment][:sha]).to eq(deployment.sha)
    end

    it 'does not expose it as an upcoming deployment' do
      expect(subject[:upcoming_deployment]).to be_nil
    end

    context 'when the deployment pipeline has the other manual job' do
      let!(:manual_job) { create(:ci_build, :manual, name: 'stop-review', project: project, pipeline: pipeline) }

      it 'exposes the manual job in the latest deployment' do
        expect(subject[:last_deployment][:manual_actions].first[:name])
          .to eq(manual_job.name)
      end
    end
  end

  context 'when there is a running deployment' do
    let!(:pipeline) { create(:ci_pipeline, :running, project: project) }
    let!(:deployable) { create(:ci_build, :running, project: project, pipeline: pipeline) }
    let!(:deployment) { create(:deployment, :running, project: project, environment: environment, deployable: deployable) }

    it 'does not expose it as the latest deployment' do
      expect(subject[:last_deployment]).to be_nil
    end

    it 'exposes it as an upcoming deployment' do
      expect(subject[:upcoming_deployment][:sha]).to eq(deployment.sha)
    end

    context 'when the deployment pipeline has the other manual job' do
      let!(:manual_job) { create(:ci_build, :manual, name: 'stop-review', project: project, pipeline: pipeline) }

      it 'does not expose the manual job in the latest deployment' do
        expect(subject[:upcoming_deployment][:manual_actions]).to be_nil
      end
    end
  end

  it "doesn't expose metrics path" do
    expect(subject).not_to include(:metrics_path)
  end

  context 'with deployment platform' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }

    context 'when deployment platform is a cluster' do
      before do
        create(
          :cluster,
          :provided_by_gcp,
          :project,
          environment_scope: '*',
          projects: [project]
        )
      end

      it 'includes cluster_type' do
        expect(subject).to include(:cluster_type)
        expect(subject[:cluster_type]).to eq('project_type')
      end
    end
  end

  context 'with auto_stop_in' do
    let(:environment) { create(:environment, :will_auto_stop, project: project) }

    it 'exposes auto stop related information' do
      project.add_maintainer(user)

      expect(subject).to include(:cancel_auto_stop_path, :auto_stop_at)
    end
  end

  context 'with deployment service ready' do
    before do
      allow(environment).to receive(:has_terminals?).and_return(true)
      allow(environment).to receive(:rollout_status).and_return(kube_deployment_rollout_status)
    end

    it 'exposes rollout_status' do
      expect(subject).to include(:rollout_status)
    end
  end

  context 'with deployment service not ready' do
    let(:user) { create(:user) }

    it 'does not expose rollout_status' do
      expect(subject).not_to include(:rollout_status)
    end
  end
end
