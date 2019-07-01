# frozen_string_literal: true

require 'spec_helper'

describe Deployment do
  subject { build(:deployment) }

  it { is_expected.to belong_to(:project).required }
  it { is_expected.to belong_to(:environment).required }
  it { is_expected.to belong_to(:cluster).class_name('Clusters::Cluster') }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:deployable) }

  it { is_expected.to delegate_method(:name).to(:environment).with_prefix }
  it { is_expected.to delegate_method(:commit).to(:project) }
  it { is_expected.to delegate_method(:commit_title).to(:commit).as(:try) }
  it { is_expected.to delegate_method(:manual_actions).to(:deployable).as(:try) }

  it { is_expected.to validate_presence_of(:ref) }
  it { is_expected.to validate_presence_of(:sha) }

  it_behaves_like 'having unique enum values'

  describe '#scheduled_actions' do
    subject { deployment.scheduled_actions }

    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:build) { create(:ci_build, :success, pipeline: pipeline) }
    let(:deployment) { create(:deployment, deployable: build) }

    it 'delegates to other_scheduled_actions' do
      expect_any_instance_of(Ci::Build)
        .to receive(:other_scheduled_actions)

      subject
    end
  end

  describe 'modules' do
    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:deployment) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: instance.project } }
      let(:usage) { :deployments }
    end
  end

  describe '.success' do
    subject { described_class.success }

    context 'when deployment status is success' do
      let(:deployment) { create(:deployment, :success) }

      it { is_expected.to eq([deployment]) }
    end

    context 'when deployment status is created' do
      let(:deployment) { create(:deployment, :created) }

      it { is_expected.to be_empty }
    end

    context 'when deployment status is running' do
      let(:deployment) { create(:deployment, :running) }

      it { is_expected.to be_empty }
    end
  end

  describe 'state machine' do
    context 'when deployment runs' do
      let(:deployment) { create(:deployment) }

      before do
        deployment.run!
      end

      it 'starts running' do
        Timecop.freeze do
          expect(deployment).to be_running
          expect(deployment.finished_at).to be_nil
        end
      end
    end

    context 'when deployment succeeded' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        Timecop.freeze do
          deployment.succeed!

          expect(deployment).to be_success
          expect(deployment.finished_at).to be_like_time(Time.now)
        end
      end

      it 'executes Deployments::SuccessWorker asynchronously' do
        expect(Deployments::SuccessWorker)
          .to receive(:perform_async).with(deployment.id)

        deployment.succeed!
      end

      it 'executes Deployments::FinishedWorker asynchronously' do
        expect(Deployments::FinishedWorker)
          .to receive(:perform_async).with(deployment.id)

        deployment.succeed!
      end
    end

    context 'when deployment failed' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        Timecop.freeze do
          deployment.drop!

          expect(deployment).to be_failed
          expect(deployment.finished_at).to be_like_time(Time.now)
        end
      end

      it 'executes Deployments::FinishedWorker asynchronously' do
        expect(Deployments::FinishedWorker)
          .to receive(:perform_async).with(deployment.id)

        deployment.drop!
      end
    end

    context 'when deployment was canceled' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        Timecop.freeze do
          deployment.cancel!

          expect(deployment).to be_canceled
          expect(deployment.finished_at).to be_like_time(Time.now)
        end
      end

      it 'executes Deployments::FinishedWorker asynchronously' do
        expect(Deployments::FinishedWorker)
          .to receive(:perform_async).with(deployment.id)

        deployment.cancel!
      end
    end
  end

  describe '#success?' do
    subject { deployment.success? }

    context 'when deployment status is success' do
      let(:deployment) { create(:deployment, :success) }

      it { is_expected.to be_truthy }
    end

    context 'when deployment status is failed' do
      let(:deployment) { create(:deployment, :failed) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#status_name' do
    subject { deployment.status_name }

    context 'when deployment status is success' do
      let(:deployment) { create(:deployment, :success) }

      it { is_expected.to eq(:success) }
    end

    context 'when deployment status is failed' do
      let(:deployment) { create(:deployment, :failed) }

      it { is_expected.to eq(:failed) }
    end
  end

  describe '#finished_at' do
    subject { deployment.finished_at }

    context 'when deployment status is created' do
      let(:deployment) { create(:deployment) }

      it { is_expected.to be_nil }
    end

    context 'when deployment status is success' do
      let(:deployment) { create(:deployment, :success) }

      it { is_expected.to eq(deployment.read_attribute(:finished_at)) }
    end

    context 'when deployment status is success' do
      let(:deployment) { create(:deployment, :success, finished_at: nil) }

      before do
        deployment.update_column(:finished_at, nil)
      end

      it { is_expected.to eq(deployment.read_attribute(:created_at)) }
    end

    context 'when deployment status is running' do
      let(:deployment) { create(:deployment, :running) }

      it { is_expected.to be_nil }
    end
  end

  describe '#deployed_at' do
    subject { deployment.deployed_at }

    context 'when deployment status is created' do
      let(:deployment) { create(:deployment) }

      it { is_expected.to be_nil }
    end

    context 'when deployment status is success' do
      let(:deployment) { create(:deployment, :success) }

      it { is_expected.to eq(deployment.read_attribute(:finished_at)) }
    end

    context 'when deployment status is running' do
      let(:deployment) { create(:deployment, :running) }

      it { is_expected.to be_nil }
    end
  end

  describe 'scopes' do
    describe 'last_for_environment' do
      let(:production) { create(:environment) }
      let(:staging) { create(:environment) }
      let(:testing) { create(:environment) }

      let!(:deployments) do
        [
          create(:deployment, environment: production),
          create(:deployment, environment: staging),
          create(:deployment, environment: production)
        ]
      end

      it 'retrieves last deployments for environments' do
        last_deployments = described_class.last_for_environment([staging, production, testing])

        expect(last_deployments.size).to eq(2)
        expect(last_deployments).to match_array(deployments.last(2))
      end
    end
  end

  describe '#includes_commit?' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }
    let(:deployment) do
      create(:deployment, environment: environment, sha: project.commit.id)
    end

    context 'when there is no project commit' do
      it 'returns false' do
        commit = project.commit('feature')

        expect(deployment.includes_commit?(commit)).to be false
      end
    end

    context 'when they share the same tree branch' do
      it 'returns true' do
        commit = project.commit

        expect(deployment.includes_commit?(commit)).to be true
      end
    end

    context 'when the SHA for the deployment does not exist in the repo' do
      it 'returns false' do
        deployment.update(sha: Gitlab::Git::BLANK_SHA)
        commit = project.commit

        expect(deployment.includes_commit?(commit)).to be false
      end
    end
  end

  describe '#has_metrics?' do
    subject { deployment.has_metrics? }

    context 'when deployment is failed' do
      let(:deployment) { create(:deployment, :failed) }

      it { is_expected.to be_falsy }
    end

    context 'when deployment is success' do
      let(:deployment) { create(:deployment, :success) }

      context 'without a monitoring service' do
        it { is_expected.to be_falsy }
      end

      context 'with a Prometheus Service' do
        let(:prometheus_service) { double(:prometheus_service, can_query?: true) }

        before do
          allow(deployment.project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
        end

        it { is_expected.to be_truthy }
      end

      context 'with a Prometheus Service that cannot query' do
        let(:prometheus_service) { double(:prometheus_service, can_query?: false) }

        before do
          allow(deployment.project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
        end

        it { is_expected.to be_falsy }
      end

      context 'with a cluster Prometheus' do
        let(:deployment) { create(:deployment, :success, :on_cluster) }
        let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: deployment.cluster) }

        before do
          expect(deployment.cluster.application_prometheus).to receive(:can_query?).and_return(true)
        end

        it { is_expected.to be_truthy }
      end

      context 'fallback deployment platform' do
        let(:cluster) { create(:cluster, :provided_by_user, environment_scope: '*', projects: [deployment.project]) }
        let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

        before do
          expect(deployment.project).to receive(:deployment_platform).and_return(cluster.platform)
          expect(cluster.application_prometheus).to receive(:can_query?).and_return(true)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#metrics' do
    let(:deployment) { create(:deployment, :success) }
    let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

    subject { deployment.metrics }

    context 'metrics are disabled' do
      it { is_expected.to eq({}) }
    end

    context 'metrics are enabled' do
      let(:simple_metrics) do
        {
          success: true,
          metrics: {},
          last_update: 42
        }
      end

      before do
        allow(deployment).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:query).with(:deployment, deployment).and_return(simple_metrics)
      end

      it { is_expected.to eq(simple_metrics.merge({ deployment_time: deployment.created_at.to_i })) }
    end
  end

  describe '#additional_metrics' do
    let(:project) { create(:project, :repository) }
    let(:deployment) { create(:deployment, :succeed, project: project) }

    subject { deployment.additional_metrics }

    context 'metrics are disabled' do
      it { is_expected.to eq({}) }
    end

    context 'metrics are enabled' do
      let(:simple_metrics) do
        {
          success: true,
          metrics: {},
          last_update: 42
        }
      end

      let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }

      before do
        allow(deployment).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        allow(prometheus_adapter).to receive(:query).with(:additional_metrics_deployment, deployment).and_return(simple_metrics)
      end

      it { is_expected.to eq(simple_metrics.merge({ deployment_time: deployment.created_at.to_i })) }
    end
  end

  describe '#stop_action' do
    let(:build) { create(:ci_build) }

    subject { deployment.stop_action }

    context 'when no other actions' do
      let(:deployment) { FactoryBot.build(:deployment, deployable: build) }

      it { is_expected.to be_nil }
    end

    context 'with other actions' do
      let!(:close_action) { create(:ci_build, :manual, pipeline: build.pipeline, name: 'close_app') }

      context 'when matching action is defined' do
        let(:deployment) { FactoryBot.build(:deployment, deployable: build, on_stop: 'close_other_app') }

        it { is_expected.to be_nil }
      end

      context 'when no matching action is defined' do
        let(:deployment) { FactoryBot.build(:deployment, deployable: build, on_stop: 'close_app') }

        it { is_expected.to eq(close_action) }
      end
    end
  end

  describe '#deployment_platform_cluster' do
    let(:deployment) { create(:deployment) }
    let(:project) { deployment.project }
    let(:environment) { deployment.environment }

    subject { deployment.deployment_platform_cluster }

    before do
      expect(project).to receive(:deployment_platform)
        .with(environment: environment.name).and_call_original
    end

    context 'project has no deployment platform' do
      before do
        expect(project.clusters).to be_empty
      end

      it { is_expected.to be_nil }
    end

    context 'project uses the kubernetes service for deployments' do
      let!(:service) { create(:kubernetes_service, project: project) }

      it { is_expected.to be_nil }
    end

    context 'project has a deployment platform' do
      let!(:cluster) { create(:cluster, projects: [project]) }
      let!(:platform) { create(:cluster_platform_kubernetes, cluster: cluster) }

      it { is_expected.to eq cluster }
    end
  end
end
