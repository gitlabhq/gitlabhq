# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment do
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
  it { is_expected.to delegate_method(:manual_actions).to(:deployable).as(:try) }
  it { is_expected.to delegate_method(:kubernetes_namespace).to(:deployment_cluster).as(:kubernetes_namespace) }

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
      expect_next_instance_of(Ci::Build) do |instance|
        expect(instance).to receive(:other_scheduled_actions)
      end

      subject
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
            .to receive(:perform_async).with(deployment_id: deployment.id, status_changed_at: Time.current)

          deployment.run!
        end
      end

      it 'executes Deployments::DropOlderDeploymentsWorker asynchronously' do
        expect(Deployments::DropOlderDeploymentsWorker)
            .to receive(:perform_async).once.with(deployment.id)

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
          .to receive(:perform_async).with(deployment_id: deployment.id, status_changed_at: Time.current)

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
            .to receive(:perform_async).with(deployment_id: deployment.id, status_changed_at: Time.current)

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
            .to receive(:perform_async).with(deployment_id: deployment.id, status_changed_at: Time.current)

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

    describe 'synching status to Jira' do
      let(:deployment) { create(:deployment) }

      let(:worker) { ::JiraConnect::SyncDeploymentsWorker }

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

    describe 'active' do
      subject { described_class.active }

      it 'retrieves the active deployments' do
        deployment1 = create(:deployment, status: :created )
        deployment2 = create(:deployment, status: :running )
        create(:deployment, status: :failed )
        create(:deployment, status: :canceled )
        create(:deployment, status: :skipped)

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

    describe 'with_deployable' do
      subject { described_class.with_deployable }

      it 'retrieves deployments with deployable builds' do
        with_deployable = create(:deployment)
        create(:deployment, deployable: nil)
        create(:deployment, deployable_type: 'CommitStatus', deployable_id: non_existing_record_id)

        is_expected.to contain_exactly(with_deployable)
      end
    end

    describe 'visible' do
      subject { described_class.visible }

      it 'retrieves the visible deployments' do
        deployment1 = create(:deployment, status: :running)
        deployment2 = create(:deployment, status: :success)
        deployment3 = create(:deployment, status: :failed)
        deployment4 = create(:deployment, status: :canceled)
        create(:deployment, status: :skipped)

        is_expected.to contain_exactly(deployment1, deployment2, deployment3, deployment4)
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
        deployment.update!(sha: Gitlab::Git::BLANK_SHA)
        commit = project.commit

        expect(deployment.includes_commit?(commit)).to be false
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
      expect(Deployments::HooksWorker).to receive(:perform_async)

      deploy.update_status('success')
    end

    it 'updates finished_at when transitioning to a finished status' do
      freeze_time do
        deploy.update_status('success')

        expect(deploy.read_attribute(:finished_at)).to eq(Time.current)
      end
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
end
