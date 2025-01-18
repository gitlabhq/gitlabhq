# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment, feature_category: :continuous_delivery do
  subject { build(:deployment) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:environment) { create(:environment, project: project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:pipeline_b) { create(:ci_pipeline, project: project) }
  let_it_be(:deployable) { create(:ci_build, project: project, pipeline: pipeline) }
  let_it_be(:deployment) { create(:deployment, project: project, environment: environment, deployable: deployable) }

  # environments
  let_it_be(:production) { create(:environment, :production, project: project) }
  let_it_be(:staging) { create(:environment, :staging, project: project) }
  let_it_be(:testing) { create(:environment, :testing, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
    it { is_expected.to belong_to(:environment).required }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:deployable) }
    it { is_expected.to have_one(:deployment_cluster) }
    it { is_expected.to have_many(:deployment_merge_requests) }
    it { is_expected.to have_many(:merge_requests).through(:deployment_merge_requests) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:name).to(:environment).with_prefix }
    it { is_expected.to delegate_method(:commit).to(:project) }
    it { is_expected.to delegate_method(:commit_title).to(:commit).as(:try) }
    it { is_expected.to delegate_method(:kubernetes_namespace).to(:deployment_cluster).as(:kubernetes_namespace) }
    it { is_expected.to delegate_method(:cluster).to(:deployment_cluster) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:ref) }
    it { is_expected.to validate_presence_of(:sha) }
  end

  it_behaves_like 'having unique enum values'

  describe '#manual_actions' do
    let(:deployment) { build(:deployment) }

    it 'delegates to environment_manual_actions' do
      expect(deployment.deployable).to receive(:other_manual_actions).and_call_original

      deployment.manual_actions
    end
  end

  describe '#scheduled_actions' do
    let(:deployment) { build(:deployment) }

    it 'delegates to environment_scheduled_actions' do
      expect(deployment.deployable).to receive(:other_scheduled_actions).and_call_original

      deployment.scheduled_actions
    end
  end

  describe 'modules' do
    it_behaves_like 'AtomicInternalId' do
      let_it_be(:deployable) { create(:ci_build, project: project) }

      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:deployment, deployable: deployable, environment: environment) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: project } }
      let(:usage) { :deployments }
    end

    it { is_expected.to include_module(EachBatch) }
  end

  describe '.success' do
    subject { described_class.success }

    context 'when deployment status is success' do
      before do
        deployment.update!(status: :success, finished_at: Time.zone.now)
      end

      it { is_expected.to eq([deployment]) }
    end

    context 'when deployment status is created' do
      before do
        deployment.update!(status: :created)
      end

      it { is_expected.to be_empty }
    end

    context 'when deployment status is running' do
      before do
        deployment.update!(status: :running)
      end

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
    end

    context 'when deployment succeeded' do
      before do
        deployment.update!(status: :running)
      end

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
      before do
        deployment.update!(status: :running)
      end

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
      before do
        deployment.update!(status: :running)
      end

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
      before do
        deployment.update!(status: :running, finished_at: nil)
      end

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
      before do
        deployment.update!(status: :created, finished_at: nil)
      end

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
    subject { deployment.older_than_last_successful_deployment? }

    context 'when deployment is current deployment' do
      before do
        deployment.update!(status: :success, finished_at: Time.zone.now)
      end

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
      before do
        deployment.update!(status: :success, finished_at: Time.zone.now)
      end

      it { is_expected.to be_truthy }
    end

    context 'when deployment status is failed' do
      before do
        deployment.update!(status: :failed, finished_at: Time.zone.now)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#status_name' do
    subject { deployment.status_name }

    context 'when deployment status is success' do
      before do
        deployment.update!(status: :success, finished_at: Time.zone.now)
      end

      it { is_expected.to eq(:success) }
    end

    context 'when deployment status is failed' do
      before do
        deployment.update!(status: :failed, finished_at: Time.zone.now)
      end

      it { is_expected.to eq(:failed) }
    end
  end

  describe '#deployed_at' do
    subject { deployment.deployed_at }

    context 'when deployment status is created' do
      it { is_expected.to be_nil }
    end

    context 'when deployment status is success' do
      before do
        deployment.update!(status: :success, finished_at: Time.zone.now)
      end

      it { is_expected.to eq(deployment.read_attribute(:finished_at)) }
    end

    context 'when deployment status is running' do
      before do
        deployment.update!(status: :running)
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'scopes' do
    let_it_be_with_reload(:deployment_2) { create(:deployment, project: project) }
    let_it_be_with_reload(:deployment_3) { create(:deployment, project: project) }

    describe '.stoppable' do
      subject { described_class.stoppable }

      context 'when deployment is stoppable' do
        before do
          deployment.update!(status: :success, finished_at: Time.zone.now, on_stop: 'stop-review')
        end

        it { is_expected.to eq([deployment]) }
      end

      context 'when deployment is not stoppable' do
        before do
          deployment.update!(status: :failed, finished_at: Time.zone.now)
        end

        it { is_expected.to be_empty }
      end
    end

    describe '.find_successful_deployment!' do
      before do
        deployment.update!(status: :success, finished_at: Time.zone.now)
      end

      it 'returns a successful deployment' do
        expect(described_class.find_successful_deployment!(deployment.iid)).to eq(deployment)
      end

      it 'raises when no deployment is found' do
        expect { described_class.find_successful_deployment!(-1) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '.jobs' do
      subject { described_class.jobs }

      it 'retrieves jobs for the deployments' do
        is_expected.to match_array([deployment.deployable, deployment_2.deployable, deployment_3.deployable])
      end

      it 'does not fetch the null deployable_ids' do
        deployment_3.update!(deployable_id: nil, deployable_type: nil)

        is_expected.to match_array([deployment.deployable, deployment_2.deployable])
      end
    end

    describe '.archivables_in' do
      subject(:archivables_in) { described_class.archivables_in(project, limit: limit) }

      let(:limit) { 100 }

      context 'when there are no archivable deployments in the project' do
        it { is_expected.to be_empty }
      end

      context 'when there are archivable deployments in the project' do
        before do
          stub_const("::Deployment::ARCHIVABLE_OFFSET", 1)
        end

        it 'returns all archivable deployments' do
          expect(archivables_in.count).to eq(2)
          expect(archivables_in).to contain_exactly(deployment, deployment_2)
        end

        context 'with limit' do
          let(:limit) { 1 }

          it 'takes the limit into account' do
            expect(archivables_in.count).to eq(1)
            expect(archivables_in.take).to be_in([deployment, deployment_2])
          end
        end
      end
    end

    describe '.for_iid' do
      subject { described_class.for_iid(project, iid) }

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

      let_it_be(:other_project) { create(:project, :repository) }
      let_it_be(:other_production) { create(:environment, :production, project: other_project) }

      let(:environment_name) { production.name }

      context 'when deployment belongs to the environment' do
        before do
          deployment.update!(environment: production)
        end

        it { is_expected.to eq([deployment]) }
      end

      context 'when deployment belongs to the same project but different environment name' do
        before do
          deployment.update!(environment: staging)
        end

        it { is_expected.to be_empty }
      end

      context 'when deployment belongs to the same environment name but different project' do
        before do
          deployment.update!(project: other_project, environment: other_production)
        end

        it { is_expected.to be_empty }
      end
    end

    describe '.last_for_environment' do
      before do
        deployment.update!(environment: production)
        deployment_2.update!(environment: staging)
        deployment_3.update!(environment: production)
      end

      let(:deployments) { [deployment, deployment_2, deployment_3] }

      it 'retrieves last deployments for environments' do
        last_deployments = described_class.last_for_environment([staging, production, testing])

        expect(last_deployments.size).to eq(2)
        expect(last_deployments).to match_array(deployments.last(2))
      end
    end

    describe '.active' do
      subject(:active) { described_class.active }

      before do
        deployment.update!(status: :created)
        deployment_2.update!(status: :running)
        deployment_3.update!(status: :failed)
      end

      it 'retrieves the active deployments' do
        create(:deployment, status: :canceled)
        create(:deployment, status: :skipped)
        create(:deployment, status: :blocked)

        is_expected.to contain_exactly(deployment, deployment_2)
      end
    end

    describe '.older_than' do
      subject(:older_than) { described_class.older_than(deployment_3) }

      it 'retrives the correct older deployments' do
        is_expected.to contain_exactly(deployment, deployment_2)
      end
    end

    describe '.finished_before' do
      before do
        deployment.update!(finished_at: 1.day.ago)
        deployment_2.update!(finished_at: Time.current)
      end

      it 'filters deployments by finished_at' do
        expect(described_class.finished_before(1.hour.ago)).to eq([deployment])
      end
    end

    describe '.finished_after' do
      before do
        deployment.update!(finished_at: 1.day.ago)
        deployment_2.update!(finished_at: Time.current)
      end

      it 'filters deployments by finished_at' do
        expect(described_class.finished_after(1.hour.ago)).to eq([deployment_2])
      end
    end

    describe '.ordered' do
      before do
        deployment.update!(status: :running)
        deployment_2.update!(status: :success, finished_at: Time.current)
        deployment_3.update!(status: :canceled, finished_at: 1.day.ago)
      end

      let!(:deployment_4) { create(:deployment, status: :success, finished_at: 2.days.ago) }

      it 'sorts by finished at' do
        expect(described_class.ordered).to eq([deployment, deployment_2, deployment_3, deployment_4])
      end
    end

    describe '.ordered_as_upcoming' do
      before do
        deployment.update!(status: :running)
        deployment_2.update!(status: :blocked)
        deployment_3.update!(status: :created)
      end

      it 'sorts by ID DESC' do
        expect(described_class.ordered_as_upcoming).to match_array([deployment_3, deployment_2, deployment])
      end
    end

    describe '.visible' do
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

    describe '.finished' do
      subject { described_class.finished }

      before do
        # unfinished deployments
        deployment.update!(status: :running)
        deployment_2.update!(status: :blocked)
        deployment_3.update!(status: :skipped)
      end

      # finished deployments
      let!(:successful_deployment) { create(:deployment, status: :success) }
      let!(:failed_deployment) { create(:deployment, status: :failed) }
      let!(:canceled_deployment) { create(:deployment, status: :canceled) }

      it 'retrieves the finished deployments' do
        is_expected.to contain_exactly(successful_deployment, failed_deployment, canceled_deployment)
      end
    end

    describe '.upcoming' do
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

    describe '.last_finished_deployment_group_for_environment' do
      subject { described_class.last_finished_deployment_group_for_environment(environment) }

      context 'when there are no deployments and jobs' do
        it { is_expected.to eq(described_class.none) }
      end

      shared_examples_for 'find last finished deployment for environment' do
        context 'when there are no finished jobs' do
          before do
            job = create(processable_type, :created, project: project, pipeline: pipeline)
            create(:deployment, :created, environment: environment, project: project, deployable: job)
          end

          it { is_expected.to eq(described_class.none) }
        end

        context 'when there are deployments for multiple pipelines' do
          # finished deployments for pipeline
          let!(:deployment_a_success) do
            job = create(processable_type, :success, project: project, pipeline: pipeline)
            create(:deployment, :success, project: project, environment: environment, deployable: job)
          end

          let!(:deployment_a_failed) do
            job = create(processable_type, :failed, project: project, pipeline: pipeline)
            create(:deployment, :failed, project: project, environment: environment, deployable: job)
          end

          let!(:deployment_a_canceled) do
            job = create(processable_type, :canceled, project: project, pipeline: pipeline)
            create(:deployment, :canceled, project: project, environment: environment, deployable: job)
          end

          before do
            # running deployment for pipeline
            job_a_running = create(processable_type, :running, project: project, pipeline: pipeline)
            create(:deployment, :running, project: project, environment: environment, deployable: job_a_running)

            # running deployment for pipeline_b
            job_b_running = create(processable_type, :running, project: project, pipeline: pipeline_b)
            create(:deployment, :running, project: project, environment: environment, deployable: job_b_running)
          end

          it 'returns the finished deployments for the last finished pipeline' do
            expect(subject.pluck(:id)).to contain_exactly(
              deployment_a_success.id, deployment_a_failed.id, deployment_a_canceled.id)
          end
        end

        context 'when last finished deployment is a retried job' do
          before do
            job = create(processable_type, :success, project: project,
              pipeline: pipeline, environment: environment.name)
            create(:deployment, :success, project: project, environment: environment, deployable: job)

            # retry job
            job.update!(retried: true)

            # new successful job after retry.
            create(
              processable_type,
              status: :success,
              finished_at: Time.current,
              project: project,
              pipeline: pipeline,
              environment: environment.name
            )
          end

          it { is_expected.not_to be_nil }
        end

        context 'when there are many environments' do
          def subject_method(env)
            described_class.last_finished_deployment_group_for_environment(env)
          end

          let_it_be(:environment_2) { create(:environment, project: project) }
          let_it_be(:pipeline_c) { create(:ci_pipeline, project: project) }
          let_it_be(:pipeline_d) { create(:ci_pipeline, project: project) }

          # stop jobs in pipeline
          let_it_be(:stop_job_a_success) do
            create(:ci_build, :manual, project: project, pipeline: pipeline, name: 'stop_a_success')
          end

          let_it_be(:stop_job_a_failed) do
            create(:ci_build, :manual, project: project, pipeline: pipeline, name: 'stop_a_failed')
          end

          let_it_be(:stop_job_a_canceled) do
            create(:ci_build, :manual, project: project, pipeline: pipeline, name: 'stop_a_canceled')
          end

          # stop jobs in pipeline_c
          let_it_be(:stop_job_c_success) do
            create(:ci_build, :manual, project: project, pipeline: pipeline_c, name: 'stop_c_success')
          end

          let_it_be(:stop_job_c_failed) do
            create(:ci_build, :manual, project: project, pipeline: pipeline_c, name: 'stop_c_failed')
          end

          let_it_be(:stop_job_c_canceled) do
            create(:ci_build, :manual, project: project, pipeline: pipeline_c, name: 'stop_c_canceled')
          end

          # finished deployments for 'environment' from pipeline
          let_it_be(:deployment_a_success) do
            job = create(processable_type, :success, project: project, pipeline: pipeline)
            create(:deployment, :success, project: project, environment: environment,
              deployable: job, on_stop: 'stop_a_success')
          end

          let_it_be(:deployment_a_failed) do
            job = create(processable_type, :failed, project: project, pipeline: pipeline)
            create(:deployment, :failed, project: project, environment: environment,
              deployable: job, on_stop: 'stop_a_failed')
          end

          let_it_be(:deployment_a_canceled) do
            job = create(processable_type, :canceled, project: project, pipeline: pipeline)
            create(:deployment, :canceled, project: project, environment: environment,
              deployable: job, on_stop: 'stop_a_canceled')
          end

          # finished deployments for 'environment_2' from pipeline_c
          let_it_be(:deployment_c_success) do
            job = create(processable_type, :success, project: project, pipeline: pipeline_c)
            create(:deployment, :success, project: project, environment: environment_2,
              deployable: job, on_stop: 'stop_c_success')
          end

          let_it_be(:deployment_c_failed) do
            job = create(processable_type, :failed, project: project, pipeline: pipeline_c)
            create(:deployment, :failed, project: project, environment: environment_2,
              deployable: job, on_stop: 'stop_c_failed')
          end

          let_it_be(:deployment_c_canceled) do
            job = create(processable_type, :canceled, project: project, pipeline: pipeline_c)
            create(:deployment, :canceled, project: project, environment: environment_2,
              deployable: job, on_stop: 'stop_c_canceled')
          end

          before_all do
            # running deployments
            job_a_running = create(processable_type, :running, project: project, pipeline: pipeline)
            create(:deployment, :running, project: project, environment: environment, deployable: job_a_running)

            job_b_running = create(processable_type, :running, project: project, pipeline: pipeline_b)
            create(:deployment, :running, project: project, environment: environment, deployable: job_b_running)

            job_c_running = create(processable_type, :running, project: project, pipeline: pipeline_c)
            create(:deployment, :running, project: project, environment: environment_2, deployable: job_c_running)

            job_d_running = create(processable_type, :running, project: project, pipeline: pipeline_d)
            create(:deployment, :running, project: project, environment: environment_2, deployable: job_d_running)
          end

          it 'batch loads for environments' do
            # Loads Batch loader
            subject_method(environment)
            subject_method(environment_2)

            expect(subject_method(environment.reload).pluck(:id))
              .to contain_exactly(deployment_a_success.id, deployment_a_failed.id, deployment_a_canceled.id)

            expect { subject_method(environment_2).pluck(:id) }.not_to exceed_query_limit(0)

            expect(subject_method(environment_2).pluck(:id))
              .to contain_exactly(deployment_c_success.id, deployment_c_failed.id, deployment_c_canceled.id)

            expect(subject_method(environment).filter_map(&:stop_action))
              .to contain_exactly(stop_job_a_success, stop_job_a_failed, stop_job_a_canceled)

            expect { subject_method(environment_2).map(&:stop_action) }
              .not_to exceed_query_limit(0)

            expect(subject_method(environment_2).filter_map(&:stop_action))
              .to contain_exactly(stop_job_c_success, stop_job_c_failed, stop_job_c_canceled)
          end
        end
      end

      it_behaves_like 'find last finished deployment for environment' do
        let_it_be(:processable_type) { :ci_build }
      end

      it_behaves_like 'find last finished deployment for environment' do
        let_it_be(:processable_type) { :ci_bridge }
      end
    end

    describe '.latest_for_sha' do
      subject { described_class.latest_for_sha(sha) }

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

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#includes_commit?' do
    before do
      deployment.update!(environment: environment, sha: project.commit.id)
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
        deployment.update!(sha: Gitlab::Git::SHA1_BLANK_SHA)
        commit = project.commit

        expect(deployment.includes_commit?(commit.id)).to be false
      end
    end
  end

  describe '#stop_action' do
    subject { deployment.stop_action }

    shared_examples_for 'stop action for a job' do
      let(:job) { create(factory_type) } # rubocop:disable Rails/SaveBang -- It is for FactoryBot.save

      context 'when no other actions' do
        let(:deployment) { FactoryBot.build(:deployment, deployable: job) }

        it { is_expected.to be_nil }
      end

      context 'with other actions' do
        let!(:close_action) { create(factory_type, :manual, pipeline: job.pipeline, name: 'close_app') }

        context 'when matching action is defined' do
          let(:deployment) { FactoryBot.build(:deployment, deployable: job, on_stop: 'close_other_app') }

          it { is_expected.to be_nil }
        end

        context 'when no matching action is defined' do
          let(:deployment) { FactoryBot.build(:deployment, deployable: job, on_stop: 'close_app') }

          it { is_expected.to eq(close_action) }
        end
      end
    end

    it_behaves_like 'stop action for a job' do
      let(:factory_type) { :ci_build }
    end

    it_behaves_like 'stop action for a job' do
      let(:factory_type) { :ci_bridge }
    end
  end

  describe '#deployed_by' do
    it 'returns the deployment user if there is no deployable' do
      deployment_user = create(:user)
      deployment = create(:deployment, deployable: nil, user: deployment_user)

      expect(deployment.deployed_by).to eq(deployment_user)
    end

    it 'returns the deployment user if the deployable is build and have no user' do
      deployment_user = create(:user)
      job = create(:ci_build, user: nil)
      deployment = create(:deployment, deployable: job, user: deployment_user)

      expect(deployment.deployed_by).to eq(deployment_user)
    end

    it 'returns the deployment user if the deployable is bridge and have no user' do
      deployment_user = create(:user)
      job = create(:ci_bridge, user: nil)
      deployment = create(:deployment, deployable: job, user: deployment_user)

      expect(deployment.deployed_by).to eq(deployment_user)
    end

    it 'returns the deployable user if there is one' do
      build_user = create(:user)
      deployment_user = create(:user)
      job = create(:ci_build, user: build_user)
      deployment = create(:deployment, deployable: job, user: deployment_user)

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

  describe '#job' do
    subject { deployment.job }

    it { is_expected.to eq(deployment.deployable) }

    it 'returns nil when the associated job is not found' do
      deployment.update!(deployable_id: nil, deployable_type: nil)

      is_expected.to be_nil
    end
  end

  describe '#previous_deployment' do
    using RSpec::Parameterized::TableSyntax

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

    subject(:create_ref) { deployment.create_ref }

    it 'creates a ref using the sha' do
      expect(deployment.project.repository).to receive(:create_ref).with(
        deployment.sha,
        "refs/environments/#{deployment.environment.name}/deployments/#{deployment.iid}"
      )

      create_ref
    end
  end

  describe '#playable_job' do
    subject(:playable_job) { deployment.playable_job }

    context 'when there is a deployable job' do
      let(:deployment) { create(:deployment, deployable: job) }

      context 'when the deployable job is build and playable' do
        let(:job) { create(:ci_build, :playable) }

        it { is_expected.to eq(job) }
      end

      context 'when the deployable job is bridge and playable' do
        let(:job) { create(:ci_bridge, :playable) }

        it { is_expected.to eq(job) }
      end

      context 'when the deployable job is not playable' do
        let(:job) { create(:ci_build) }

        it { is_expected.to be_nil }
      end
    end

    context 'when there is no deployable job' do
      it { is_expected.to be_nil }
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

    context 'when an invalid status transition is detected' do
      it 'tracks an exception' do
        expect(Gitlab::ErrorTracking)
        .to receive(:track_exception)
        .with(instance_of(described_class::StatusUpdateError), deployment_id: deploy.id)

        expect(deploy.update_status('running')).to eq(false)
      end

      it 'tracks an exception' do
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

    context 'when mapping status to event' do
      using RSpec::Parameterized::TableSyntax

      where(:status, :method) do
        'running'   | :run!
        'success'   | :succeed!
        'failed'    | :drop!
        'canceling' | nil
        'canceled'  | :cancel!
        'skipped'   | :skip!
        'blocked'   | :block!
      end

      with_them do
        it 'calls the correct method for the given status' do
          expect(deploy).to receive(method) if method

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

    context 'when each job status is passed' do
      Deployment.statuses.each do |starting_status, _|
        Ci::HasStatus::AVAILABLE_STATUSES.each do |status|
          it "#{starting_status} to #{status} does not cause an error" do
            deploy.update!(status: starting_status)
            expect { deploy.update_status(status) }.not_to raise_error
          end
        end
      end
    end
  end

  describe '#sync_status_with' do
    subject { deployment.sync_status_with(job) }

    shared_examples_for 'sync status with a job' do
      let(:deployment) { create(:deployment, project: project, status: deployment_status) }
      let(:job) { create(factory_type, project: project, status: job_status) }

      shared_examples_for 'synchronizing deployment' do
        let(:expected_deployment_status) { job_status.to_s }

        it 'changes deployment status' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          is_expected.to eq(true)

          expect(deployment.status).to eq(expected_deployment_status)
          expect(deployment.errors).to be_empty
        end
      end

      shared_examples_for 'gracefully handling error' do
        it 'tracks an exception' do
          expect(Gitlab::ErrorTracking).to(
            receive(:track_exception).with(
              instance_of(described_class::StatusSyncError),
              deployment_id: deployment.id,
              job_id: job.id
            ) do |error|
              expect(error.backtrace).to be_present
            end
          )

          is_expected.to eq(false)

          expect(deployment.status).to eq(deployment_status.to_s)
          expect(deployment.errors.full_messages).to include(error_message)
        end
      end

      shared_examples_for 'ignoring job' do
        it 'does not change deployment status' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          is_expected.to eq(false)

          expect(deployment.status).to eq(deployment_status.to_s)
          expect(deployment.errors).to be_empty
        end
      end

      context 'with created deployment' do
        let(:deployment_status) { :created }

        context 'with created job' do
          let(:job_status) { :created }

          it_behaves_like 'ignoring job'
        end

        context 'with manual job' do
          let(:job_status) { :manual }

          it_behaves_like 'synchronizing deployment' do
            let(:expected_deployment_status) { 'blocked' }
          end
        end

        context 'with running job' do
          let(:job_status) { :running }

          it_behaves_like 'synchronizing deployment'
        end

        context 'with finished job' do
          let(:job_status) { :success }

          it_behaves_like 'synchronizing deployment'
        end

        context 'with unrelated job' do
          let(:job_status) { :waiting_for_resource }

          it_behaves_like 'ignoring job'
        end
      end

      context 'with running deployment' do
        let(:deployment_status) { :running }

        context 'with created job' do
          let(:job_status) { :created }

          it_behaves_like 'gracefully handling error' do
            let(:error_message) { %(Status cannot transition via \"create\") }
          end
        end

        context 'with manual job' do
          let(:job_status) { :manual }

          it_behaves_like 'gracefully handling error' do
            let(:error_message) { %(Status cannot transition via \"block\") }
          end
        end

        context 'with running job' do
          let(:job_status) { :running }

          it_behaves_like 'ignoring job'
        end

        context 'with finished job' do
          let(:job_status) { :success }

          it_behaves_like 'synchronizing deployment'
        end

        context 'with unrelated job' do
          let(:job_status) { :waiting_for_resource }

          it_behaves_like 'ignoring job'
        end
      end

      context 'with finished deployment' do
        let(:deployment_status) { :success }

        context 'with created job' do
          let(:job_status) { :created }

          it_behaves_like 'gracefully handling error' do
            let(:error_message) { %(Status cannot transition via \"create\") }
          end
        end

        context 'with manual job' do
          let(:job_status) { :manual }

          it_behaves_like 'gracefully handling error' do
            let(:error_message) { %(Status cannot transition via \"block\") }
          end
        end

        context 'with running job' do
          let(:job_status) { :running }

          it_behaves_like 'gracefully handling error' do
            let(:error_message) { %(Status cannot transition via \"run\") }
          end
        end

        context 'with finished job' do
          let(:job_status) { :success }

          it_behaves_like 'ignoring job'
        end

        context 'with failed job' do
          let(:job_status) { :failed }

          it_behaves_like 'synchronizing deployment'
        end

        context 'with unrelated job' do
          let(:job_status) { :waiting_for_resource }

          it_behaves_like 'ignoring job'
        end
      end
    end

    it_behaves_like 'sync status with a job' do
      let(:factory_type) { :ci_build }
    end

    it_behaves_like 'sync status with a job' do
      let(:factory_type) { :ci_bridge }
    end

    context 'when each job status is passed' do
      Deployment.statuses.each do |starting_status, _|
        Ci::HasStatus::AVAILABLE_STATUSES.each do |status|
          it "#{starting_status} to #{status} does not cause an error" do
            deployment.update!(status: starting_status)
            job = create(:ci_build, status: status)
            expect { deployment.sync_status_with(job) }.not_to raise_error
          end
        end
      end
    end
  end

  describe '#tags' do
    let(:deployment) { build(:deployment, project: project) }

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
    let(:deployment) { build(:deployment) }

    subject(:tier_in_yaml) { deployment.tier_in_yaml }

    context 'when deployable is nil' do
      before do
        deployment.deployable = nil
      end

      it { is_expected.to be_nil }
    end

    context 'when deployable is present' do
      context 'when tier is specified' do
        let(:deployable) { build(:ci_build, :success, :environment_with_deployment_tier) }

        before do
          deployment.deployable = deployable
        end

        it { is_expected.to eq('testing') }

        context 'when deployable is a bridge job' do
          let(:deployable) { build(:ci_bridge, :success, :environment_with_deployment_tier) }

          it { is_expected.to eq('testing') }
        end

        context 'when tier is not specified' do
          let(:deployable) { build(:ci_build, :success) }

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '.fast_destroy_all' do
    it 'cleans path_refs for destroyed environments' do
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

    it 'does not trigger N+1 queries' do
      create(:deployment, environment: environment, project: project)

      control = ActiveRecord::QueryRecorder.new { project.deployments.fast_destroy_all }

      create_list(:deployment, 2, environment: environment, project: project)

      expect { project.deployments.fast_destroy_all }.not_to exceed_query_limit(control)
    end

    context 'when repository was already removed' do
      it 'removes deployment without any errors' do
        deployment = create(:deployment, environment: environment, project: project)

        ::Repositories::DestroyService.new(project.repository).execute
        project.save! # to trigger a repository removal

        expect { described_class.where(id: deployment).fast_destroy_all }
          .to change { Deployment.count }.by(-1)
      end
    end
  end

  describe '#update_merge_request_metrics!' do
    let_it_be(:merge_request) { create(:merge_request, :simple, :merged_last_month, project: project) }

    context 'with production environment' do
      before do
        deployment.update!(status: :success, finished_at: Time.current, environment: production)
      end

      it 'updates merge request metrics for production-grade environment' do
        expect { deployment.update_merge_request_metrics! }
          .to change { merge_request.reload.metrics.first_deployed_to_production_at }
          .from(nil).to(deployment.reload.finished_at)
      end
    end

    context 'with staging environment' do
      before do
        deployment.update!(status: :success, finished_at: Time.current, environment: staging)
      end

      it 'updates merge request metrics for production-grade environment' do
        expect { deployment.update_merge_request_metrics! }
          .not_to change { merge_request.reload.metrics.first_deployed_to_production_at }
      end
    end
  end
end
