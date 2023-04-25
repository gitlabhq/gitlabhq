# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment, feature_category: :continuous_delivery do
  subject { build(:deployment) }

  it { is_expected.to belong_to(:project).required }
  it { is_expected.to belong_to(:environment).required }
  it { is_expected.to belong_to(:cluster).class_name('Clusters::Cluster') }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:deployable) }
  it { is_expected.to have_one(:deployment_cluster) }
  it { is_expected.to have_many(:deployment_merge_requests) }
  it { is_expected.to have_many(:merge_requests).through(:deployment_merge_requests) }

  it { is_expected.to delegate_method(:name).to(:environment).with_prefix }
  it { is_expected.to delegate_method(:commit).to(:project) }
  it { is_expected.to delegate_method(:commit_title).to(:commit).as(:try) }
  it { is_expected.to delegate_method(:kubernetes_namespace).to(:deployment_cluster).as(:kubernetes_namespace) }

  it { is_expected.to validate_presence_of(:ref) }
  it { is_expected.to validate_presence_of(:sha) }

  it_behaves_like 'having unique enum values'

  describe '#manual_actions' do
    let(:deployment) { create(:deployment) }

    it 'delegates to environment_manual_actions' do
      expect(deployment.deployable).to receive(:other_manual_actions).and_call_original

      deployment.manual_actions
    end
  end

  describe '#scheduled_actions' do
    let(:deployment) { create(:deployment) }

    it 'delegates to environment_scheduled_actions' do
      expect(deployment.deployable).to receive(:other_scheduled_actions).and_call_original

      deployment.scheduled_actions
    end
  end

  describe 'modules' do
    it_behaves_like 'AtomicInternalId' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:deployable) { create(:ci_build, project: project) }
      let_it_be(:environment) { create(:environment, project: project) }

      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:deployment, deployable: deployable, environment: environment) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: project } }
      let(:usage) { :deployments }
    end
  end

  describe '.stoppable' do
    subject { described_class.stoppable }

    context 'when deployment is stoppable' do
      let!(:deployment) { create(:deployment, :success, on_stop: 'stop-review') }

      it { is_expected.to eq([deployment]) }
    end

    context 'when deployment is not stoppable' do
      let!(:deployment) { create(:deployment, :failed) }

      it { is_expected.to be_empty }
    end
  end

  describe '.for_iid' do
    subject { described_class.for_iid(project, iid) }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:deployment) { create(:deployment, project: project) }

    let(:iid) { deployment.iid }

    it 'finds the deployment' do
      is_expected.to contain_exactly(deployment)
    end

    context 'when iid does not match' do
      let(:iid) { non_existing_record_id }

      it 'does not find the deployment' do
        is_expected.to be_empty
      end
    end
  end

  describe '.for_environment_name' do
    subject { described_class.for_environment_name(project, environment_name) }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:production) { create(:environment, :production, project: project) }
    let_it_be(:staging) { create(:environment, :staging, project: project) }
    let_it_be(:other_project) { create(:project, :repository) }
    let_it_be(:other_production) { create(:environment, :production, project: other_project) }

    let(:environment_name) { production.name }

    context 'when deployment belongs to the environment' do
      let!(:deployment) { create(:deployment, project: project, environment: production) }

      it { is_expected.to eq([deployment]) }
    end

    context 'when deployment belongs to the same project but different environment name' do
      let!(:deployment) { create(:deployment, project: project, environment: staging) }

      it { is_expected.to be_empty }
    end

    context 'when deployment belongs to the same environment name but different project' do
      let!(:deployment) { create(:deployment, project: other_project, environment: other_production) }

      it { is_expected.to be_empty }
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

      it 'starts running' do
        freeze_time do
          deployment.run!

          expect(deployment).to be_running
          expect(deployment.finished_at).to be_nil
        end
      end

      it 'executes Deployments::HooksWorker asynchronously' do
        freeze_time do
          expect(Deployments::HooksWorker)
            .to receive(:perform_async)
                  .with(hash_including({ 'deployment_id' => deployment.id, 'status' => 'running',
                                         'status_changed_at' => Time.current.to_s }))

          deployment.run!
        end
      end

      it 'does not execute Deployments::DropOlderDeploymentsWorker' do
        expect(Deployments::DropOlderDeploymentsWorker)
          .not_to receive(:perform_async).with(deployment.id)

        deployment.run!
      end
    end

    context 'when deployment succeeded' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        freeze_time do
          deployment.succeed!

          expect(deployment).to be_success
          expect(deployment.finished_at).to be_like_time(Time.current)
        end
      end

      it 'executes Deployments::UpdateEnvironmentWorker asynchronously' do
        expect(Deployments::UpdateEnvironmentWorker)
          .to receive(:perform_async).with(deployment.id)

        deployment.succeed!
      end

      it 'executes Deployments::HooksWorker asynchronously' do
        freeze_time do
          expect(Deployments::HooksWorker)
            .to receive(:perform_async)
                  .with(hash_including({ 'deployment_id' => deployment.id, 'status' => 'success',
                                         'status_changed_at' => Time.current.to_s }))

          deployment.succeed!
        end
      end
    end

    context 'when deployment failed' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        freeze_time do
          deployment.drop!

          expect(deployment).to be_failed
          expect(deployment.finished_at).to be_like_time(Time.current)
        end
      end

      it 'does not execute Deployments::LinkMergeRequestWorker' do
        expect(Deployments::LinkMergeRequestWorker)
          .not_to receive(:perform_async).with(deployment.id)

        deployment.drop!
      end

      it 'executes Deployments::HooksWorker asynchronously' do
        freeze_time do
          expect(Deployments::HooksWorker)
            .to receive(:perform_async)
                  .with(hash_including({ 'deployment_id' => deployment.id, 'status' => 'failed',
                                         'status_changed_at' => Time.current.to_s }))

          deployment.drop!
        end
      end
    end

    context 'when deployment was canceled' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        freeze_time do
          deployment.cancel!

          expect(deployment).to be_canceled
          expect(deployment.finished_at).to be_like_time(Time.current)
        end
      end

      it 'does not execute Deployments::LinkMergeRequestWorker' do
        expect(Deployments::LinkMergeRequestWorker)
          .not_to receive(:perform_async).with(deployment.id)

        deployment.cancel!
      end

      it 'executes Deployments::HooksWorker asynchronously' do
        freeze_time do
          expect(Deployments::HooksWorker)
            .to receive(:perform_async)
                  .with(hash_including({ 'deployment_id' => deployment.id, 'status' => 'canceled',
                                         'status_changed_at' => Time.current.to_s }))
          deployment.cancel!
        end
      end
    end

    context 'when deployment was skipped' do
      let(:deployment) { create(:deployment, :running) }

      it 'has correct status' do
        deployment.skip!

        expect(deployment).to be_skipped
        expect(deployment.finished_at).to be_nil
      end

      it 'does not execute Deployments::LinkMergeRequestWorker asynchronously' do
        expect(Deployments::LinkMergeRequestWorker)
          .not_to receive(:perform_async).with(deployment.id)

        deployment.skip!
      end

      it 'does not execute Deployments::HooksWorker' do
        freeze_time do
          expect(Deployments::HooksWorker)
            .not_to receive(:perform_async).with(deployment_id: deployment.id, status_changed_at: Time.current)

          deployment.skip!
        end
      end
    end

    context 'when deployment is blocked' do
      let(:deployment) { create(:deployment, :created) }

      it 'has correct status' do
        deployment.block!

        expect(deployment).to be_blocked
        expect(deployment.finished_at).to be_nil
      end

      it 'does not execute Deployments::LinkMergeRequestWorker asynchronously' do
        expect(Deployments::LinkMergeRequestWorker).not_to receive(:perform_async)

        deployment.block!
      end

      it 'does not execute Deployments::HooksWorker' do
        expect(Deployments::HooksWorker).not_to receive(:perform_async)

        deployment.block!
      end
    end

    describe 'synching status to Jira' do
      let_it_be(:project) { create(:project, :repository) }

      let(:deployment) { create(:deployment, project: project) }
      let(:worker) { ::JiraConnect::SyncDeploymentsWorker }

      context 'when Jira Connect subscription does not exist' do
        it 'does not call the worker' do
          expect(worker).not_to receive(:perform_async)

          deployment
        end
      end

      context 'when Jira Connect subscription exists' do
        before_all do
          create(:jira_connect_subscription, namespace: project.namespace)
        end

        it 'calls the worker on creation' do
          expect(worker).to receive(:perform_async).with(Integer)

          deployment
        end

        it 'does not call the worker for skipped deployments' do
          expect(deployment).to be_present # warm-up, ignore the creation trigger

          expect(worker).not_to receive(:perform_async)

          deployment.skip!
        end

        %i[run! succeed! drop! cancel!].each do |event|
          context "when we call pipeline.#{event}" do
            it 'triggers a Jira synch worker' do
              expect(worker).to receive(:perform_async).with(deployment.id)

              deployment.send(event)
            end
          end
        end
      end
    end
  end

  describe '#older_than_last_successful_deployment?' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:environment) { create(:environment, project: project) }

    subject { deployment.older_than_last_successful_deployment? }

    context 'when deployment is current deployment' do
      let(:deployment) { create(:deployment, :success, project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when deployment is behind current deployment' do
      let_it_be(:commits) { project.repository.commits('master', limit: 2) }

      let!(:deployment) do
        create(
          :deployment,
          :success,
          project: project,
          environment: environment,
          finished_at: 1.year.ago,
          sha: commits[0].sha
        )
      end

      let!(:last_deployment) do
        create(:deployment, :success, project: project, environment: environment, sha: commits[1].sha)
      end

      it { is_expected.to be_truthy }
    end

    context 'when deployment is the same sha as the current deployment' do
      let!(:deployment) do
        create(:deployment, :success, project: project, environment: environment, finished_at: 1.year.ago)
      end

      let!(:last_deployment) do
        create(:deployment, :success, project: project, environment: environment, sha: deployment.sha)
      end

      it { is_expected.to be_falsey }
    end

    context 'when environment is undefined' do
      let(:deployment) { build(:deployment, :success, project: project, environment: environment) }

      before do
        deployment.environment = nil
      end

      it { is_expected.to be_falsey }
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

  describe '.archivables_in' do
    subject { described_class.archivables_in(project, limit: limit) }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:deployment_1) { create(:deployment, project: project) }
    let_it_be(:deployment_2) { create(:deployment, project: project) }
    let_it_be(:deployment_3) { create(:deployment, project: project) }

    let(:limit) { 100 }

    context 'when there are no archivable deployments in the project' do
      it 'returns nothing' do
        expect(subject).to be_empty
      end
    end

    context 'when there are archivable deployments in the project' do
      before do
        stub_const("::Deployment::ARCHIVABLE_OFFSET", 1)
      end

      it 'returns all archivable deployments' do
        expect(subject.count).to eq(2)
        expect(subject).to contain_exactly(deployment_1, deployment_2)
      end

      context 'with limit' do
        let(:limit) { 1 }

        it 'takes the limit into account' do
          expect(subject.count).to eq(1)
          expect(subject.take).to be_in([deployment_1, deployment_2])
        end
      end
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

    describe 'active' do
      subject { described_class.active }

      it 'retrieves the active deployments' do
        deployment1 = create(:deployment, status: :created)
        deployment2 = create(:deployment, status: :running)
        create(:deployment, status: :failed)
        create(:deployment, status: :canceled)
        create(:deployment, status: :skipped)
        create(:deployment, status: :blocked)

        is_expected.to contain_exactly(deployment1, deployment2)
      end
    end

    describe 'older_than' do
      let(:deployment) { create(:deployment) }

      subject { described_class.older_than(deployment) }

      it 'retrives the correct older deployments' do
        older_deployment1 = create(:deployment)
        older_deployment2 = create(:deployment)
        deployment
        create(:deployment)

        is_expected.to contain_exactly(older_deployment1, older_deployment2)
      end
    end

    describe '.finished_before' do
      let!(:deployment1) { create(:deployment, finished_at: 1.day.ago) }
      let!(:deployment2) { create(:deployment, finished_at: Time.current) }

      it 'filters deployments by finished_at' do
        expect(described_class.finished_before(1.hour.ago))
          .to eq([deployment1])
      end
    end

    describe '.finished_after' do
      let!(:deployment1) { create(:deployment, finished_at: 1.day.ago) }
      let!(:deployment2) { create(:deployment, finished_at: Time.current) }

      it 'filters deployments by finished_at' do
        expect(described_class.finished_after(1.hour.ago))
          .to eq([deployment2])
      end
    end

    describe '.ordered' do
      let!(:deployment1) { create(:deployment, status: :running) }
      let!(:deployment2) { create(:deployment, status: :success, finished_at: Time.current) }
      let!(:deployment3) { create(:deployment, status: :canceled, finished_at: 1.day.ago) }
      let!(:deployment4) { create(:deployment, status: :success, finished_at: 2.days.ago) }

      it 'sorts by finished at' do
        expect(described_class.ordered).to eq([deployment1, deployment2, deployment3, deployment4])
      end
    end

    describe '.ordered_as_upcoming' do
      let!(:deployment1) { create(:deployment, status: :running) }
      let!(:deployment2) { create(:deployment, status: :blocked) }
      let!(:deployment3) { create(:deployment, status: :created) }

      it 'sorts by ID DESC' do
        expect(described_class.ordered_as_upcoming).to eq([deployment3, deployment2, deployment1])
      end
    end

    describe 'visible' do
      subject { described_class.visible }

      it 'retrieves the visible deployments' do
        deployment1 = create(:deployment, status: :running)
        deployment2 = create(:deployment, status: :success)
        deployment3 = create(:deployment, status: :failed)
        deployment4 = create(:deployment, status: :canceled)
        deployment5 = create(:deployment, status: :blocked)
        create(:deployment, status: :skipped)

        is_expected.to contain_exactly(deployment1, deployment2, deployment3, deployment4, deployment5)
      end

      it 'has a corresponding database index' do
        index = ApplicationRecord.connection.indexes('deployments').find do |i|
          i.name == 'index_deployments_for_visible_scope'
        end

        scope_values = described_class::VISIBLE_STATUSES.map { |s| described_class.statuses[s] }.to_s

        expect(index.where).to include(scope_values)
      end
    end

    describe 'upcoming' do
      subject { described_class.upcoming }

      it 'retrieves the upcoming deployments' do
        deployment1 = create(:deployment, status: :running)
        deployment2 = create(:deployment, status: :blocked)
        create(:deployment, status: :success)
        create(:deployment, status: :failed)
        create(:deployment, status: :canceled)
        create(:deployment, status: :skipped)

        is_expected.to contain_exactly(deployment1, deployment2)
      end
    end

    describe 'last_deployment_group_for_environment' do
      def subject_method(environment)
        described_class.last_deployment_group_for_environment(environment)
      end

      let!(:project) { create(:project, :repository) }
      let!(:environment) { create(:environment, project: project) }

      context 'when there are no deployments and builds' do
        it do
          expect(subject_method(environment)).to eq(Deployment.none)
        end
      end

      context 'when there are no successful builds' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:ci_build) { create(:ci_build, :running, project: project, pipeline: pipeline) }

        before do
          create(:deployment, :success, environment: environment, project: project, deployable: ci_build)
        end

        it do
          expect(subject_method(environment)).to eq(Deployment.none)
        end
      end

      context 'when there are deployments for multiple pipelines' do
        let(:pipeline_a) { create(:ci_pipeline, project: project) }
        let(:pipeline_b) { create(:ci_pipeline, project: project) }
        let(:ci_build_a) { create(:ci_build, :success, project: project, pipeline: pipeline_a) }
        let(:ci_build_b) { create(:ci_build, :failed, project: project, pipeline: pipeline_b) }
        let(:ci_build_c) { create(:ci_build, :success, project: project, pipeline: pipeline_a) }
        let(:ci_build_d) { create(:ci_build, :failed, project: project, pipeline: pipeline_a) }

        # Successful deployments for pipeline_a
        let!(:deployment_a) do
          create(:deployment, :success, project: project, environment: environment, deployable: ci_build_a)
        end

        let!(:deployment_b) do
          create(:deployment, :success, project: project, environment: environment, deployable: ci_build_c)
        end

        before do
          # Failed deployment for pipeline_a
          create(:deployment, :failed, project: project, environment: environment, deployable: ci_build_d)

          # Failed deployment for pipeline_b
          create(:deployment, :failed, project: project, environment: environment, deployable: ci_build_b)
        end

        it 'returns the successful deployment jobs for the last deployment pipeline' do
          expect(subject_method(environment).pluck(:id)).to contain_exactly(deployment_a.id, deployment_b.id)
        end
      end

      context 'when there are many environments' do
        let(:environment_b) { create(:environment, project: project) }

        let(:pipeline_a) { create(:ci_pipeline, project: project) }
        let(:pipeline_b) { create(:ci_pipeline, project: project) }
        let(:pipeline_c) { create(:ci_pipeline, project: project) }
        let(:pipeline_d) { create(:ci_pipeline, project: project) }

        # Builds for first environment: 'environment' with pipeline_a and pipeline_b
        let(:ci_build_a) { create(:ci_build, :success, project: project, pipeline: pipeline_a) }
        let(:ci_build_b) { create(:ci_build, :failed, project: project, pipeline: pipeline_b) }
        let(:ci_build_c) { create(:ci_build, :success, project: project, pipeline: pipeline_a) }
        let(:ci_build_d) { create(:ci_build, :failed, project: project, pipeline: pipeline_a) }
        let!(:stop_env_a) { create(:ci_build, :manual, project: project, pipeline: pipeline_a, name: 'stop_env_a') }

        # Builds for second environment: 'environment_b' with pipeline_c and pipeline_d
        let(:ci_build_e) { create(:ci_build, :success, project: project, pipeline: pipeline_c) }
        let(:ci_build_f) { create(:ci_build, :failed, project: project, pipeline: pipeline_d) }
        let(:ci_build_g) { create(:ci_build, :success, project: project, pipeline: pipeline_c) }
        let(:ci_build_h) { create(:ci_build, :failed, project: project, pipeline: pipeline_c) }
        let!(:stop_env_b) { create(:ci_build, :manual, project: project, pipeline: pipeline_c, name: 'stop_env_b') }

        # Successful deployments for 'environment' from pipeline_a
        let!(:deployment_a) do
          create(:deployment, :success, project: project, environment: environment, deployable: ci_build_a)
        end

        let!(:deployment_b) do
          create(:deployment, :success,
            project: project, environment: environment, deployable: ci_build_c, on_stop: 'stop_env_a')
        end

        # Successful deployments for 'environment_b' from pipeline_c
        let!(:deployment_c) do
          create(:deployment, :success, project: project, environment: environment_b, deployable: ci_build_e)
        end

        let!(:deployment_d) do
          create(:deployment, :success,
            project: project, environment: environment_b, deployable: ci_build_g, on_stop: 'stop_env_b')
        end

        before do
          # Failed deployment for 'environment' from pipeline_a and pipeline_b
          create(:deployment, :failed, project: project, environment: environment, deployable: ci_build_d)
          create(:deployment, :failed, project: project, environment: environment, deployable: ci_build_b)

          # Failed deployment for 'environment_b' from pipeline_c and pipeline_d
          create(:deployment, :failed, project: project, environment: environment_b, deployable: ci_build_h)
          create(:deployment, :failed, project: project, environment: environment_b, deployable: ci_build_f)
        end

        it 'batch loads for environments' do
          environments = [environment, environment_b]

          # Loads Batch loader
          environments.each do |env|
            subject_method(env)
          end

          expect(subject_method(environments.first).pluck(:id))
            .to contain_exactly(deployment_a.id, deployment_b.id)

          expect { subject_method(environments.second).pluck(:id) }.not_to exceed_query_limit(0)

          expect(subject_method(environments.second).pluck(:id))
            .to contain_exactly(deployment_c.id, deployment_d.id)

          expect(subject_method(environments.first).map(&:stop_action).compact)
            .to contain_exactly(stop_env_a)

          expect { subject_method(environments.second).map(&:stop_action) }
            .not_to exceed_query_limit(0)

          expect(subject_method(environments.second).map(&:stop_action).compact)
            .to contain_exactly(stop_env_b)
        end
      end

      context 'When last deployment for environment is a retried build' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:environment_b) { create(:environment, project: project) }

        let(:build_a) do
          create(:ci_build, :success, project: project, pipeline: pipeline, environment: environment.name)
        end

        let(:build_b) do
          create(:ci_build, :success, project: project, pipeline: pipeline, environment: environment_b.name)
        end

        let!(:deployment_a) do
          create(:deployment, :success, project: project, environment: environment, deployable: build_a)
        end

        let!(:deployment_b) do
          create(:deployment, :success, project: project, environment: environment_b, deployable: build_b)
        end

        before do
          # Retry build_b
          build_b.update!(retried: true)

          # New successful build after retry.
          create(:ci_build, :success, project: project, pipeline: pipeline, environment: environment_b.name)
        end

        it { expect(subject_method(environment_b)).not_to be_nil }
      end
    end
  end

  describe 'latest_for_sha' do
    subject { described_class.latest_for_sha(sha) }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:commits) { project.repository.commits('master', limit: 2) }
    let_it_be(:deployments) { commits.reverse.map { |commit| create(:deployment, project: project, sha: commit.id) } }

    let(:sha) { commits.map(&:id) }

    it 'finds the latest deployment with sha' do
      is_expected.to eq(deployments.last)
    end

    context 'when sha is old' do
      let(:sha) { commits.last.id }

      it 'finds the latest deployment with sha' do
        is_expected.to eq(deployments.first)
      end
    end

    context 'when sha is nil' do
      let(:sha) { nil }

      it 'returns nothing' do
        is_expected.to be_nil
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

        expect(deployment.includes_commit?(commit.id)).to be false
      end
    end

    context 'when they share the same tree branch' do
      it 'returns true' do
        commit = project.commit

        expect(deployment.includes_commit?(commit.id)).to be true
      end
    end

    context 'when the SHA for the deployment does not exist in the repo' do
      it 'returns false' do
        deployment.update!(sha: Gitlab::Git::BLANK_SHA)
        commit = project.commit

        expect(deployment.includes_commit?(commit.id)).to be false
      end
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

  describe '#deployed_by' do
    it 'returns the deployment user if there is no deployable' do
      deployment_user = create(:user)
      deployment = create(:deployment, deployable: nil, user: deployment_user)

      expect(deployment.deployed_by).to eq(deployment_user)
    end

    it 'returns the deployment user if the deployable have no user' do
      deployment_user = create(:user)
      build = create(:ci_build, user: nil)
      deployment = create(:deployment, deployable: build, user: deployment_user)

      expect(deployment.deployed_by).to eq(deployment_user)
    end

    it 'returns the deployable user if there is one' do
      build_user = create(:user)
      deployment_user = create(:user)
      build = create(:ci_build, user: build_user)
      deployment = create(:deployment, deployable: build, user: deployment_user)

      expect(deployment.deployed_by).to eq(build_user)
    end
  end

  describe '#triggered_by?' do
    subject { deployment.triggered_by?(user) }

    let(:user) { create(:user) }
    let(:deployment) { create(:deployment, user: user) }

    it { is_expected.to eq(true) }

    context 'when deployment triggerer is different' do
      let(:deployment) { create(:deployment) }

      it { is_expected.to eq(false) }
    end
  end

  describe '.find_successful_deployment!' do
    it 'returns a successful deployment' do
      deploy = create(:deployment, :success)

      expect(described_class.find_successful_deployment!(deploy.iid)).to eq(deploy)
    end

    it 'raises when no deployment is found' do
      expect { described_class.find_successful_deployment!(-1) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.builds' do
    let!(:deployment1) { create(:deployment) }
    let!(:deployment2) { create(:deployment) }
    let!(:deployment3) { create(:deployment) }

    subject { described_class.builds }

    it 'retrieves builds for the deployments' do
      is_expected.to match_array(
        [deployment1.deployable, deployment2.deployable, deployment3.deployable])
    end

    it 'does not fetch the null deployable_ids' do
      deployment3.update!(deployable_id: nil, deployable_type: nil)

      is_expected.to match_array(
        [deployment1.deployable, deployment2.deployable])
    end
  end

  describe '#build' do
    let!(:deployment) { create(:deployment) }

    subject { deployment.build }

    it 'retrieves build for the deployment' do
      is_expected.to eq(deployment.deployable)
    end

    it 'returns nil when the associated build is not found' do
      deployment.update!(deployable_id: nil, deployable_type: nil)

      is_expected.to be_nil
    end
  end

  describe '#previous_deployment' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:production) { create(:environment, :production, project: project) }
    let_it_be(:staging) { create(:environment, :staging, project: project) }
    let_it_be(:production_deployment_1) { create(:deployment, :success, project: project, environment: production) }
    let_it_be(:production_deployment_2) { create(:deployment, :success, project: project, environment: production) }
    let_it_be(:production_deployment_3) { create(:deployment, :failed, project: project, environment: production) }
    let_it_be(:production_deployment_4) { create(:deployment, :canceled, project: project, environment: production) }
    let_it_be(:staging_deployment_1)    { create(:deployment, :failed, project: project, environment: staging) }
    let_it_be(:staging_deployment_2)    { create(:deployment, :success, project: project, environment: staging) }
    let_it_be(:production_deployment_5) { create(:deployment, :success, project: project, environment: production) }
    let_it_be(:staging_deployment_3)    { create(:deployment, :success, project: project, environment: staging) }

    where(:pointer, :expected_previous_deployment) do
      'production_deployment_1'   | nil
      'production_deployment_2'   | 'production_deployment_1'
      'production_deployment_3'   | 'production_deployment_2'
      'production_deployment_4'   | 'production_deployment_2'
      'staging_deployment_1'      | nil
      'staging_deployment_2'      | nil
      'production_deployment_5'   | 'production_deployment_2'
      'staging_deployment_3'      | 'staging_deployment_2'
    end

    with_them do
      it 'returns the previous deployment' do
        if expected_previous_deployment.nil?
          expect(send(pointer).previous_deployment).to eq(expected_previous_deployment)
        else
          expect(send(pointer).previous_deployment).to eq(send(expected_previous_deployment))
        end
      end
    end
  end

  describe '#link_merge_requests' do
    it 'links merge requests with a deployment' do
      deploy = create(:deployment)
      mr1 = create(
        :merge_request,
        :merged,
        target_project: deploy.project,
        source_project: deploy.project
      )

      mr2 = create(
        :merge_request,
        :merged,
        target_project: deploy.project,
        source_project: deploy.project
      )

      deploy.link_merge_requests(deploy.project.merge_requests)

      expect(deploy.merge_requests).to include(mr1, mr2)
    end

    it 'ignores already linked merge requests' do
      deploy = create(:deployment)
      mr1 = create(
        :merge_request,
        :merged,
        target_project: deploy.project,
        source_project: deploy.project
      )

      deploy.link_merge_requests(deploy.project.merge_requests)

      mr2 = create(
        :merge_request,
        :merged,
        target_project: deploy.project,
        source_project: deploy.project
      )

      deploy.link_merge_requests(deploy.project.merge_requests)

      expect(deploy.merge_requests).to include(mr1, mr2)
    end
  end

  describe '#create_ref' do
    let(:deployment) { build(:deployment) }

    subject { deployment.create_ref }

    it 'creates a ref using the sha' do
      expect(deployment.project.repository).to receive(:create_ref).with(
        deployment.sha,
        "refs/environments/#{deployment.environment.name}/deployments/#{deployment.iid}"
      )

      subject
    end
  end

  describe '#playable_build' do
    subject { deployment.playable_build }

    context 'when there is a deployable build' do
      let(:deployment) { create(:deployment, deployable: build) }

      context 'when the deployable build is playable' do
        let(:build) { create(:ci_build, :playable) }

        it 'returns that build' do
          is_expected.to eq(build)
        end
      end

      context 'when the deployable build is not playable' do
        let(:build) { create(:ci_build) }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end

    context 'when there is no deployable build' do
      let(:deployment) { create(:deployment) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#update_status' do
    let(:deploy) { create(:deployment, status: :running) }

    it 'changes the status' do
      deploy.update_status('success')

      expect(deploy).to be_success
    end

    it 'schedules workers when finishing a deploy' do
      expect(Deployments::UpdateEnvironmentWorker).to receive(:perform_async)
      expect(Deployments::LinkMergeRequestWorker).to receive(:perform_async)
      expect(Deployments::ArchiveInProjectWorker).to receive(:perform_async)
      expect(Deployments::HooksWorker).to receive(:perform_async)

      expect(deploy.update_status('success')).to eq(true)
    end

    it 'updates finished_at when transitioning to a finished status' do
      freeze_time do
        deploy.update_status('success')

        expect(deploy.read_attribute(:finished_at)).to eq(Time.current)
      end
    end

    context 'tracks an exception if an invalid status transition is detected' do
      it do
        expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(instance_of(described_class::StatusUpdateError), deployment_id: deploy.id)

        expect(deploy.update_status('running')).to eq(false)
      end

      it do
        deploy.update_status('success')

        expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(instance_of(described_class::StatusUpdateError), deployment_id: deploy.id)

        expect(deploy.update_status('created')).to eq(false)
      end
    end

    it 'tracks an exception if an invalid argument' do
      expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(instance_of(described_class::StatusUpdateError), deployment_id: deploy.id)

      expect(deploy.update_status('recreate')).to eq(false)
    end

    context 'mapping status to event' do
      using RSpec::Parameterized::TableSyntax

      where(:status, :method) do
        'running'  | :run!
        'success'  | :succeed!
        'failed'   | :drop!
        'canceled' | :cancel!
        'skipped'  | :skip!
        'blocked'  | :block!
      end

      with_them do
        it 'calls the correct method for the given status' do
          expect(deploy).to receive(method)

          deploy.update_status(status)
        end
      end

      context 'for created status update' do
        let(:deploy) { create(:deployment, status: :created) }

        it 'calls the correct method' do
          expect(deploy).to receive(:create!)

          deploy.update_status('created')
        end
      end
    end
  end

  describe '#sync_status_with' do
    subject { deployment.sync_status_with(ci_build) }

    let_it_be(:project) { create(:project, :repository) }

    let(:deployment) { create(:deployment, project: project, status: deployment_status) }
    let(:ci_build) { create(:ci_build, project: project, status: build_status) }

    shared_examples_for 'synchronizing deployment' do
      it 'changes deployment status' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        is_expected.to eq(true)

        expect(deployment.status).to eq(build_status.to_s)
        expect(deployment.errors).to be_empty
      end
    end

    shared_examples_for 'gracefully handling error' do
      it 'tracks an exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(described_class::StatusSyncError),
          deployment_id: deployment.id,
          build_id: ci_build.id)

        is_expected.to eq(false)

        expect(deployment.status).to eq(deployment_status.to_s)
        expect(deployment.errors.full_messages).to include(error_message)
      end
    end

    shared_examples_for 'ignoring build' do
      it 'does not change deployment status' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        is_expected.to eq(false)

        expect(deployment.status).to eq(deployment_status.to_s)
        expect(deployment.errors).to be_empty
      end
    end

    context 'with created deployment' do
      let(:deployment_status) { :created }

      context 'with created build' do
        let(:build_status) { :created }

        it_behaves_like 'ignoring build'
      end

      context 'with running build' do
        let(:build_status) { :running }

        it_behaves_like 'synchronizing deployment'
      end

      context 'with finished build' do
        let(:build_status) { :success }

        it_behaves_like 'synchronizing deployment'
      end

      context 'with unrelated build' do
        let(:build_status) { :waiting_for_resource }

        it_behaves_like 'ignoring build'
      end
    end

    context 'with running deployment' do
      let(:deployment_status) { :running }

      context 'with created build' do
        let(:build_status) { :created }

        it_behaves_like 'gracefully handling error' do
          let(:error_message) { %Q{Status cannot transition via \"create\"} }
        end
      end

      context 'with running build' do
        let(:build_status) { :running }

        it_behaves_like 'ignoring build'
      end

      context 'with finished build' do
        let(:build_status) { :success }

        it_behaves_like 'synchronizing deployment'
      end

      context 'with unrelated build' do
        let(:build_status) { :waiting_for_resource }

        it_behaves_like 'ignoring build'
      end
    end

    context 'with finished deployment' do
      let(:deployment_status) { :success }

      context 'with created build' do
        let(:build_status) { :created }

        it_behaves_like 'gracefully handling error' do
          let(:error_message) { %Q{Status cannot transition via \"create\"} }
        end
      end

      context 'with running build' do
        let(:build_status) { :running }

        it_behaves_like 'gracefully handling error' do
          let(:error_message) { %Q{Status cannot transition via \"run\"} }
        end
      end

      context 'with finished build' do
        let(:build_status) { :success }

        it_behaves_like 'ignoring build'
      end

      context 'with failed build' do
        let(:build_status) { :failed }

        it_behaves_like 'synchronizing deployment'
      end

      context 'with unrelated build' do
        let(:build_status) { :waiting_for_resource }

        it_behaves_like 'ignoring build'
      end
    end
  end

  describe '#tags' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:deployment) { create(:deployment, project: project) }

    subject { deployment.tags }

    it 'will return tags related to this deployment' do
      expect(project.repository).to receive(:refs_by_oid).with(
        oid: deployment.sha, limit: 100, ref_patterns: [Gitlab::Git::TAG_REF_PREFIX]
      ).and_return(["#{Gitlab::Git::TAG_REF_PREFIX}test"])

      is_expected.to match_array(['refs/tags/test'])
    end
  end

  describe '#valid_sha' do
    it 'does not add errors for a valid SHA' do
      project = create(:project, :repository)
      deploy = build(:deployment, project: project)

      expect(deploy).to be_valid
    end

    it 'adds an error for an invalid SHA' do
      deploy = build(:deployment, sha: 'foo')

      expect(deploy).not_to be_valid
      expect(deploy.errors[:sha]).not_to be_empty
    end
  end

  describe '#valid_ref' do
    it 'does not add errors for a valid ref' do
      project = create(:project, :repository)
      deploy = build(:deployment, project: project)

      expect(deploy).to be_valid
    end

    it 'adds an error for an invalid ref' do
      deploy = build(:deployment, ref: 'does-not-exist')

      expect(deploy).not_to be_valid
      expect(deploy.errors[:ref]).not_to be_empty
    end
  end

  describe '#tier_in_yaml' do
    context 'when deployable is nil' do
      before do
        subject.deployable = nil
      end

      it 'returns nil' do
        expect(subject.tier_in_yaml).to be_nil
      end
    end

    context 'when deployable is present' do
      context 'when tier is specified' do
        let(:deployable) { create(:ci_build, :success, :environment_with_deployment_tier) }

        before do
          subject.deployable = deployable
        end

        it 'returns the tier' do
          expect(subject.tier_in_yaml).to eq('testing')
        end

        context 'when tier is not specified' do
          let(:deployable) { create(:ci_build, :success) }

          it 'returns nil' do
            expect(subject.tier_in_yaml).to be_nil
          end
        end
      end
    end
  end

  describe '.fast_destroy_all' do
    it 'cleans path_refs for destroyed environments' do
      project = create(:project, :repository)
      environment = create(:environment, project: project)

      destroyed_deployments = create_list(:deployment, 2, :success, environment: environment, project: project)
      other_deployments = create_list(:deployment, 2, :success, environment: environment, project: project)

      (destroyed_deployments + other_deployments).each(&:create_ref)

      described_class.where(id: destroyed_deployments.map(&:id)).fast_destroy_all

      destroyed_deployments.each do |deployment|
        expect(project.commit(deployment.ref_path)).to be_nil
      end

      other_deployments.each do |deployment|
        expect(project.commit(deployment.ref_path)).not_to be_nil
      end
    end
  end

  describe '#update_merge_request_metrics!' do
    let_it_be(:project) { create(:project, :repository) }

    let(:environment) { build(:environment, environment_tier, project: project) }
    let!(:deployment) { create(:deployment, :success, project: project, environment: environment) }
    let!(:merge_request) { create(:merge_request, :simple, :merged_last_month, project: project) }

    context 'with production environment' do
      let(:environment_tier) { :production }

      it 'updates merge request metrics for production-grade environment' do
        expect { deployment.update_merge_request_metrics! }
          .to change { merge_request.reload.metrics.first_deployed_to_production_at }
          .from(nil).to(deployment.reload.finished_at)
      end
    end

    context 'with staging environment' do
      let(:environment_tier) { :staging }

      it 'updates merge request metrics for production-grade environment' do
        expect { deployment.update_merge_request_metrics! }
          .not_to change { merge_request.reload.metrics.first_deployed_to_production_at }
      end
    end
  end

  context 'loose foreign key on deployments.cluster_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:cluster) }
      let!(:model) { create(:deployment, cluster: parent) }
    end
  end
end
