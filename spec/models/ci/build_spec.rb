# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Build, feature_category: :continuous_integration, factory_default: :keep do
  using RSpec::Parameterized::TableSyntax
  include Ci::TemplateHelpers
  include AfterNextHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create_default(:group, :allow_runner_registration_token) }
  let_it_be(:project, reload: true) { create_default(:project, :repository, group: group) }

  let_it_be(:pipeline, reload: true) do
    create_default(
      :ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success'
    )
  end

  let_it_be(:build, refind: true) { create(:ci_build, pipeline: pipeline) }

  let(:allow_runner_registration_token) { false }
  let_it_be(:public_project) { create(:project, :public) }

  before do
    stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
  end

  it { is_expected.to belong_to(:runner) }
  it { is_expected.to belong_to(:trigger_request) }
  it { is_expected.to belong_to(:erased_by) }
  it { is_expected.to belong_to(:pipeline).inverse_of(:builds) }
  it { is_expected.to belong_to(:execution_config).class_name('Ci::BuildExecutionConfig').inverse_of(:builds) }

  it { is_expected.to have_many(:needs).with_foreign_key(:build_id) }

  it do
    is_expected.to have_many(:sourced_pipelines).class_name('Ci::Sources::Pipeline').with_foreign_key(:source_job_id)
      .inverse_of(:build)
  end

  it { is_expected.to have_many(:job_variables).with_foreign_key(:job_id) }
  it { is_expected.to have_many(:report_results).with_foreign_key(:build_id) }
  it { is_expected.to have_many(:pages_deployments).with_foreign_key(:ci_build_id) }
  it { is_expected.to have_many(:taggings).with_foreign_key(:build_id).class_name('Ci::BuildTag').inverse_of(:build) }
  it { is_expected.to have_many(:tags).class_name('Ci::Tag').through(:taggings).source(:tag) }

  it { is_expected.to have_one(:runner_manager).through(:runner_manager_build) }
  it { is_expected.to have_one(:runner_session).with_foreign_key(:build_id) }
  it { is_expected.to have_one(:trace_metadata).with_foreign_key(:build_id) }
  it { is_expected.to have_one(:runtime_metadata).with_foreign_key(:build_id) }
  it { is_expected.to have_one(:pending_state).with_foreign_key(:build_id).inverse_of(:build) }

  it do
    is_expected.to have_one(:queuing_entry).class_name('Ci::PendingBuild').with_foreign_key(:build_id).inverse_of(:build)
  end

  it do
    is_expected.to have_one(:runtime_metadata).class_name('Ci::RunningBuild').with_foreign_key(:build_id)
      .inverse_of(:build)
  end

  it { is_expected.to have_many(:terraform_state_versions).inverse_of(:build).with_foreign_key(:ci_build_id) }

  it { is_expected.to validate_presence_of(:ref) }

  it { is_expected.to respond_to(:has_trace?) }
  it { is_expected.to respond_to(:trace) }
  it { is_expected.to respond_to(:set_cancel_gracefully) }
  it { is_expected.to respond_to(:cancel_gracefully?) }

  it { is_expected.to delegate_method(:merge_request?).to(:pipeline) }
  it { is_expected.to delegate_method(:merge_request_ref?).to(:pipeline) }
  it { is_expected.to delegate_method(:legacy_detached_merge_request_pipeline?).to(:pipeline) }

  describe 'partition query' do
    subject { build.reload }

    it_behaves_like 'including partition key for relation', :trace_chunks
    it_behaves_like 'including partition key for relation', :build_source
    it_behaves_like 'including partition key for relation', :job_artifacts
    it_behaves_like 'including partition key for relation', :job_annotations
    it_behaves_like 'including partition key for relation', :runner_manager_build
    Ci::JobArtifact.file_types.each_key do |key|
      it_behaves_like 'including partition key for relation', :"job_artifacts_#{key}"
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project_mirror).with_foreign_key('project_id') }

    it 'has a bidirectional relationship with projects' do
      expect(described_class.reflect_on_association(:project).has_inverse?).to eq(:builds)
      expect(Project.reflect_on_association(:builds).has_inverse?).to eq(:project)
    end

    it 'has a bidirectional relationship with project mirror' do
      expect(described_class.reflect_on_association(:project_mirror).has_inverse?).to eq(:builds)
      expect(Ci::ProjectMirror.reflect_on_association(:builds).has_inverse?).to eq(:project_mirror)
    end
  end

  describe 'scopes' do
    let_it_be(:old_project) { create(:project) }
    let_it_be(:new_project) { create(:project) }
    let_it_be(:old_build) { create(:ci_build, created_at: 1.week.ago, updated_at: 1.week.ago, project: old_project) }
    let_it_be(:new_build) { create(:ci_build, created_at: 1.minute.ago, updated_at: 1.minute.ago, project: new_project) }

    describe 'created_after' do
      subject { described_class.created_after(1.day.ago) }

      it 'returns the builds created after the given time' do
        is_expected.to contain_exactly(new_build, build)
      end
    end

    describe 'updated_after' do
      subject { described_class.updated_after(1.day.ago) }

      it 'returns the builds updated after the given time' do
        is_expected.to contain_exactly(new_build, build)
      end
    end

    describe 'with_pipeline_source_type' do
      let_it_be(:pipeline) { create(:ci_pipeline, source: :security_orchestration_policy) }
      let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
      let_it_be(:push_pipeline) { create(:ci_pipeline, source: :push) }
      let_it_be(:push_build) { create(:ci_build, pipeline: push_pipeline) }

      subject { described_class.with_pipeline_source_type('security_orchestration_policy') }

      it 'returns the builds updated after the given time' do
        is_expected.to contain_exactly(build)
      end
    end

    describe 'for_project_ids' do
      subject { described_class.for_project_ids([new_project.id]) }

      it 'returns the builds from given projects' do
        is_expected.to contain_exactly(new_build)
      end
    end
  end

  describe 'callbacks' do
    context 'when running after_create callback' do
      it 'executes hooks' do
        expect_next(described_class).to receive(:execute_hooks)

        create(:ci_build, pipeline: pipeline)
      end
    end

    context 'when running after_commit callbacks' do
      it 'tracks creation event' do
        expect(Gitlab::InternalEvents).to receive(:track_event).with(
          'create_ci_build',
          project: project,
          user: user
        )

        create(:ci_build, user: user, project: project)
      end
    end
  end

  describe 'status' do
    context 'when transitioning to any state from running' do
      it 'removes runner_session' do
        %w[success drop cancel].each do |event|
          build = create(:ci_build, :running, :with_runner_session, pipeline: pipeline)

          build.fire_events!(event)

          expect(build.reload.runner_session).to be_nil
        end
      end
    end
  end

  it_behaves_like 'has ID tokens', :ci_build

  it_behaves_like 'a retryable job'

  it_behaves_like 'a deployable job' do
    let(:job) { build }
  end

  it_behaves_like 'a triggerable processable', :ci_build

  describe '.ref_protected' do
    subject { described_class.ref_protected }

    context 'when protected is true' do
      let!(:job) { create(:ci_build, :protected, pipeline: pipeline) }

      it { is_expected.to include(job) }
    end

    context 'when protected is false' do
      let!(:job) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.not_to include(job) }
    end

    context 'when protected is nil' do
      let!(:job) { create(:ci_build, pipeline: pipeline) }

      before do
        job.update_attribute(:protected, nil)
      end

      it { is_expected.not_to include(job) }
    end
  end

  describe '.with_downloadable_artifacts' do
    subject { described_class.with_downloadable_artifacts }

    context 'when job does not have a downloadable artifact' do
      let!(:job) { create(:ci_build, pipeline: pipeline) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end

    ::Enums::Ci::JobArtifact.downloadable_types.each do |type|
      context "when job has a #{type} artifact" do
        it 'returns the job' do
          job = create(:ci_build, pipeline: pipeline)
          create(
            :ci_job_artifact,
            file_format: ::Enums::Ci::JobArtifact.type_and_format_pairs[type.to_sym],
            file_type: type,
            job: job
          )

          is_expected.to include(job)
        end
      end
    end

    context 'when job has a non-downloadable artifact' do
      let!(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end
  end

  describe '.with_erasable_artifacts' do
    subject { described_class.with_erasable_artifacts }

    context 'when job does not have any artifacts' do
      let!(:job) { create(:ci_build, pipeline: pipeline) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end

    ::Ci::JobArtifact.erasable_file_types.each do |type|
      context "when job has a #{type} artifact" do
        it 'returns the job' do
          job = create(:ci_build, pipeline: pipeline)
          create(
            :ci_job_artifact,
            file_format: ::Enums::Ci::JobArtifact.type_and_format_pairs[type.to_sym],
            file_type: type,
            job: job
          )

          is_expected.to include(job)
        end
      end
    end

    context 'when job has a non-erasable artifact' do
      let!(:job) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end
  end

  describe '.with_any_artifacts' do
    subject { described_class.with_any_artifacts }

    context 'when job does not have any artifacts' do
      it 'does not return the job' do
        job = create(:ci_build, project: project)

        is_expected.not_to include(job)
      end
    end

    ::Ci::JobArtifact.file_types.each_key do |type|
      context "when job has a #{type} artifact" do
        it 'returns the job' do
          job = create(:ci_build, project: project)
          create(
            :ci_job_artifact,
            file_format: ::Enums::Ci::JobArtifact.type_and_format_pairs[type.to_sym],
            file_type: type,
            job: job
          )

          is_expected.to include(job)
        end
      end
    end
  end

  describe '.with_live_trace' do
    subject { described_class.with_live_trace }

    context 'when build has live trace' do
      let!(:build) { create(:ci_build, :success, :trace_live, pipeline: pipeline) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build does not have live trace' do
      let!(:build) { create(:ci_build, :success, :trace_artifact, pipeline: pipeline) }

      it 'does not select the build' do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_stale_live_trace' do
    subject { described_class.with_stale_live_trace }

    context 'when build has a stale live trace' do
      let!(:build) { create(:ci_build, :success, :trace_live, finished_at: 1.day.ago, pipeline: pipeline) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build does not have a stale live trace' do
      let!(:build) { create(:ci_build, :success, :trace_live, finished_at: 1.hour.ago, pipeline: pipeline) }

      it 'does not select the build' do
        is_expected.to be_empty
      end
    end
  end

  describe '.license_management_jobs' do
    subject { described_class.license_management_jobs }

    let!(:management_build) { create(:ci_build, :success, name: :license_management, pipeline: pipeline) }
    let!(:scanning_build) { create(:ci_build, :success, name: :license_scanning, pipeline: pipeline) }
    let!(:another_build) { create(:ci_build, :success, name: :another_type, pipeline: pipeline) }

    it 'returns license_scanning jobs' do
      is_expected.to include(scanning_build)
    end

    it 'returns license_management jobs' do
      is_expected.to include(management_build)
    end

    it 'doesnt return filtered out jobs' do
      is_expected.not_to include(another_build)
    end
  end

  describe '.finished_before' do
    subject { described_class.finished_before(date) }

    let(:date) { 1.hour.ago }

    context 'when build has finished one day ago' do
      let!(:build) { create(:ci_build, :success, finished_at: 1.day.ago, pipeline: pipeline) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build has finished 30 minutes ago' do
      let!(:build) { create(:ci_build, :success, finished_at: 30.minutes.ago, pipeline: pipeline) }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'when build is still running' do
      let!(:build) { create(:ci_build, :running, pipeline: pipeline) }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_exposed_artifacts' do
    subject { described_class.with_exposed_artifacts }

    let_it_be(:job1) { create(:ci_build, pipeline: pipeline) }
    let_it_be(:job3) { create(:ci_build, pipeline: pipeline) }

    let!(:job2) { create(:ci_build, options: options, pipeline: pipeline) }

    context 'when some jobs have exposed artifacts and some not' do
      let(:options) { { artifacts: { expose_as: 'test', paths: ['test'] } } }

      before_all do
        job1.ensure_metadata.update!(has_exposed_artifacts: nil)
        job3.ensure_metadata.update!(has_exposed_artifacts: false)
      end

      it 'selects only the jobs with exposed artifacts' do
        is_expected.to eq([job2])
      end
    end

    context 'when job does not expose artifacts' do
      let(:options) { nil }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_artifacts' do
    subject(:builds) { described_class.with_artifacts(artifact_scope) }

    let(:artifact_scope) { Ci::JobArtifact.where(file_type: 'archive') }

    let_it_be(:build_1) { create(:ci_build, :artifacts, pipeline: pipeline) }
    let_it_be(:build_2) { create(:ci_build, :codequality_reports, pipeline: pipeline) }
    let_it_be(:build_3) { create(:ci_build, :test_reports, pipeline: pipeline) }
    let_it_be(:build_4) { create(:ci_build, :artifacts, pipeline: pipeline) }

    it 'returns artifacts matching the given scope' do
      expect(builds).to contain_exactly(build_1, build_4)
    end

    context 'when there are multiple builds containing artifacts' do
      before do
        create_list(:ci_build, 5, :success, :test_reports, pipeline: pipeline)
      end

      it 'does not execute a query for selecting job artifact one by one' do
        recorded = ActiveRecord::QueryRecorder.new do
          builds.each do |build|
            build.job_artifacts.map { |a| a.file.exists? }
          end
        end

        expect(recorded.count).to eq(2)
      end
    end
  end

  describe '.with_needs' do
    let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
    let_it_be(:build_b) { create(:ci_build, pipeline: pipeline) }
    let_it_be(:build_need_a) { create(:ci_build_need, build: build) }
    let_it_be(:build_need_b) { create(:ci_build_need, build: build_b) }

    context 'when passing build name' do
      subject { described_class.with_needs(build_need_a.name) }

      it { is_expected.to contain_exactly(build) }
    end

    context 'when not passing any build name' do
      subject { described_class.with_needs }

      it { is_expected.to contain_exactly(build, build_b) }
    end

    context 'when not matching build name' do
      subject { described_class.with_needs('undefined') }

      it { is_expected.to be_empty }
    end
  end

  describe '.without_needs' do
    subject { described_class.without_needs }

    context 'when no build_need is created' do
      it { is_expected.to contain_exactly(build) }
    end

    context 'when a build_need is created' do
      let!(:need_a) { create(:ci_build_need, build: build) }

      it { is_expected.to be_empty }
    end
  end

  describe '.belonging_to_runner_manager' do
    subject { described_class.belonging_to_runner_manager(runner_manager) }

    let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }
    let_it_be(:build_b) { create(:ci_build, :success) }

    context 'with runner_manager of runner associated with build' do
      let!(:runner_manager) { create(:ci_runner_machine, runner: runner) }
      let!(:runner_manager_build) { create(:ci_runner_machine_build, build: build, runner_manager: runner_manager) }

      it { is_expected.to contain_exactly(build) }
    end

    context 'with runner_manager of runner not associated with build' do
      let!(:runner_manager) { create(:ci_runner_machine, runner: instance_runner) }
      let!(:instance_runner) { create(:ci_runner, :with_runner_manager) }

      it { is_expected.to be_empty }
    end

    context 'with nil runner_manager' do
      let(:runner_manager) { nil }

      it { is_expected.to be_empty }
    end
  end

  describe 'scopes for preloading' do
    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:user) { create(:user) }

    before_all do
      build = create(:ci_build, :trace_artifact, :artifacts, :test_reports, pipeline: pipeline)
      build.runner = runner
      build.user = user
      build.save!
    end

    describe '.eager_load_for_api' do
      subject(:eager_load_for_api) { described_class.eager_load_for_api }

      it { expect(eager_load_for_api.last.association(:user)).to be_loaded }
      it { expect(eager_load_for_api.last.user.association(:user_detail)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:metadata)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:job_artifacts_archive)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:job_artifacts)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:runner)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:tags)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:ci_stage)).to be_loaded }
      it { expect(eager_load_for_api.last.association(:pipeline)).to be_loaded }
      it { expect(eager_load_for_api.last.pipeline.association(:project)).to be_loaded }
    end
  end

  describe '#stick_build_if_status_changed' do
    it 'sticks the build if the status changed' do
      job = create(:ci_build, :pending, pipeline: pipeline)

      expect(described_class.sticking).to receive(:stick)
        .with(:build, job.id)

      job.update!(status: :running)
    end
  end

  describe '#enqueue' do
    let(:build) { create(:ci_build, :created, pipeline: pipeline) }

    before do
      allow(build).to receive(:any_unmet_prerequisites?).and_return(has_prerequisites)
      allow(Ci::PrepareBuildService).to receive(:perform_async)
    end

    context 'build has unmet prerequisites' do
      let(:has_prerequisites) { true }

      it 'transitions to preparing' do
        build.enqueue

        expect(build).to be_preparing
      end

      it 'does not push build to the queue' do
        build.enqueue

        expect(build.queuing_entry).not_to be_present
      end
    end

    context 'build has no prerequisites' do
      let(:has_prerequisites) { false }

      it 'transitions to pending' do
        build.enqueue

        expect(build).to be_pending
      end

      it 'pushes build to a queue' do
        build.enqueue

        expect(build.queuing_entry).to be_present
      end

      context 'when build status transition fails' do
        before do
          ::Ci::Build.find(build.id).update_column(:lock_version, 100)
        end

        it 'does not push build to a queue' do
          expect { build.enqueue! }
            .to raise_error(ActiveRecord::StaleObjectError)

          expect(build.queuing_entry).not_to be_present
        end
      end

      context 'when there is a queuing entry already present' do
        before do
          create(:ci_pending_build, build: build, project: build.project)
        end

        it 'does not raise an error' do
          expect { build.enqueue! }.not_to raise_error
          expect(build.reload.queuing_entry).to be_present
        end
      end

      context 'when both failure scenario happen at the same time' do
        before do
          ::Ci::Build.find(build.id).update_column(:lock_version, 100)
          create(:ci_pending_build, build: build, project: build.project)
        end

        it 'raises stale object error exception' do
          expect { build.enqueue! }
            .to raise_error(ActiveRecord::StaleObjectError)
        end
      end
    end
  end

  describe '#enqueue_preparing' do
    let(:build) { create(:ci_build, :preparing, pipeline: pipeline) }

    before do
      allow(build).to receive(:any_unmet_prerequisites?).and_return(has_unmet_prerequisites)
    end

    context 'build completed prerequisites' do
      let(:has_unmet_prerequisites) { false }

      it 'transitions to pending' do
        build.enqueue_preparing

        expect(build).to be_pending
        expect(build.queuing_entry).to be_present
      end
    end

    context 'build did not complete prerequisites' do
      let(:has_unmet_prerequisites) { true }

      it 'remains in preparing' do
        build.enqueue_preparing

        expect(build).to be_preparing
        expect(build.queuing_entry).not_to be_present
      end
    end
  end

  describe '#actionize' do
    context 'when build is a created' do
      before do
        build.update_column(:status, :created)
      end

      it 'makes build a manual action' do
        expect(build.actionize).to be true
        expect(build.reload).to be_manual
      end
    end

    context 'when build is not created' do
      before do
        build.update_column(:status, :pending)
      end

      it 'does not change build status' do
        expect(build.actionize).to be false
        expect(build.reload).to be_pending
      end
    end
  end

  describe '#run' do
    context 'when build has been just created' do
      let(:build) { create(:ci_build, :created, pipeline: pipeline) }

      it 'creates queuing entry and then removes it' do
        build.enqueue!
        expect(build.queuing_entry).to be_present

        build.run!
        expect(build.reload.queuing_entry).not_to be_present
      end
    end

    context 'when build status transition fails' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline) }

      before do
        create(:ci_pending_build, build: build, project: build.project)
        ::Ci::Build.find(build.id).update_column(:lock_version, 100)
      end

      it 'does not remove build from a queue' do
        expect { build.run! }
          .to raise_error(ActiveRecord::StaleObjectError)

        expect(build.queuing_entry).to be_present
      end
    end

    context 'when build has been picked by a shared runner' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline) }

      it 'creates runtime metadata entry' do
        build.runner = create(:ci_runner, :instance_type)

        build.run!

        expect(build.reload.runtime_metadata).to be_present
      end
    end
  end

  describe '#drop' do
    context 'when has a runtime tracking entry' do
      let(:build) { create(:ci_build, :pending, pipeline: pipeline) }

      it 'removes runtime tracking entry' do
        build.runner = create(:ci_runner, :instance_type)

        build.run!
        expect(build.reload.runtime_metadata).to be_present

        build.drop!
        expect(build.reload.runtime_metadata).not_to be_present
      end
    end

    context 'when a failure reason is provided' do
      context 'when a failure reason is a symbol' do
        it 'correctly sets a failure reason' do
          build.drop!(:script_failure)

          expect(build.failure_reason).to eq 'script_failure'
        end
      end

      context 'when a failure reason is an object' do
        it 'correctly sets a failure reason' do
          reason = ::Gitlab::Ci::Build::Status::Reason.new(build, :script_failure)

          build.drop!(reason)

          expect(build.failure_reason).to eq 'script_failure'
        end
      end
    end
  end

  describe '#schedulable?' do
    subject { build.schedulable? }

    context 'when build is schedulable' do
      let(:build) { create(:ci_build, :created, :schedulable, pipeline: pipeline) }

      it { expect(subject).to be_truthy }
    end

    context 'when build is not schedulable' do
      let(:build) { create(:ci_build, :created, pipeline: pipeline) }

      it { expect(subject).to be_falsy }
    end
  end

  describe '#schedule' do
    subject { build.schedule }

    before do
      project.add_developer(user)
    end

    let(:build) { create(:ci_build, :created, :schedulable, user: user, pipeline: pipeline) }

    it 'transits to scheduled' do
      allow(Ci::BuildScheduleWorker).to receive(:perform_at)

      subject

      expect(build).to be_scheduled
    end

    it 'updates scheduled_at column' do
      allow(Ci::BuildScheduleWorker).to receive(:perform_at)

      subject

      expect(build.scheduled_at).not_to be_nil
    end

    it 'schedules BuildScheduleWorker at the right time' do
      freeze_time do
        expect(Ci::BuildScheduleWorker)
          .to receive(:perform_at).with(be_like_time(1.minute.since), build.id)

        subject
      end
    end
  end

  describe '#unschedule' do
    subject { build.unschedule }

    context 'when build is scheduled' do
      let(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

      it 'cleans scheduled_at column' do
        subject

        expect(build.scheduled_at).to be_nil
      end

      it 'transits to manual' do
        subject

        expect(build).to be_manual
      end
    end

    context 'when build is not scheduled' do
      let(:build) { create(:ci_build, :created, pipeline: pipeline) }

      it 'does not transit status' do
        subject

        expect(build).to be_created
      end
    end
  end

  describe '#options_scheduled_at' do
    subject { build.options_scheduled_at }

    let(:build) { build_stubbed(:ci_build, options: option, pipeline: pipeline) }

    context 'when start_in is 1 day' do
      let(:option) { { start_in: '1 day' } }

      it 'returns date after 1 day' do
        freeze_time do
          is_expected.to eq(1.day.since)
        end
      end
    end

    context 'when start_in is 1 week' do
      let(:option) { { start_in: '1 week' } }

      it 'returns date after 1 week' do
        freeze_time do
          is_expected.to eq(1.week.since)
        end
      end
    end
  end

  describe '#enqueue_scheduled' do
    subject { build.enqueue_scheduled }

    context 'when build is scheduled and the right time has not come yet' do
      let(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

      it 'does not transits the status' do
        subject

        expect(build).to be_scheduled
      end
    end

    context 'when build is scheduled and the right time has already come' do
      let(:build) { create(:ci_build, :expired_scheduled, pipeline: pipeline) }

      it 'cleans scheduled_at column' do
        subject

        expect(build.scheduled_at).to be_nil
      end

      it 'transits to pending' do
        subject

        expect(build).to be_pending
      end

      context 'build has unmet prerequisites' do
        before do
          allow(build).to receive(:prerequisites).and_return([double])
        end

        it 'transits to preparing' do
          subject

          expect(build).to be_preparing
        end
      end
    end
  end

  describe '#any_runners_online?', :freeze_time do
    subject { build.any_runners_online? }

    context 'when no runners' do
      it { is_expected.to be_falsey }
    end

    context 'when there is a runner' do
      before do
        create(:ci_runner, *Array.wrap(runner_traits), :project, projects: [build.project])
      end

      context 'that is online' do
        let(:runner_traits) { :online }

        it { is_expected.to be_truthy }

        context 'and almost offline' do
          let(:runner_traits) { :almost_offline }

          it { is_expected.to be_truthy }
        end
      end

      context 'that is paused' do
        let(:runner_traits) { [:online, :paused] }

        it { is_expected.to be_falsey }
      end

      context 'that is offline' do
        let(:runner_traits) { :offline }

        it { is_expected.to be_falsey }
      end

      context 'that cannot handle build' do
        let(:runner_traits) { :online }

        before do
          expect_any_instance_of(Gitlab::Ci::Matching::RunnerMatcher).to receive(:matches?).with(build.build_matcher)
            .and_return(false)
        end

        it { is_expected.to be_falsey }
      end
    end

    it 'caches the result in Redis' do
      expect(Rails.cache).to receive(:fetch).with(['has-online-runners', build.id], expires_in: 1.minute)

      build.any_runners_online?
    end
  end

  describe '#any_runners_available?' do
    subject { build.any_runners_available? }

    context 'when no runners' do
      it { is_expected.to be_falsey }
    end

    context 'when there are runners' do
      let!(:runner) { create(:ci_runner, :project, projects: [build.project]) }

      it { is_expected.to be_truthy }
    end

    it 'caches the result in Redis' do
      expect(Rails.cache).to receive(:fetch).with(['has-available-runners', build.project.id], expires_in: 1.minute)

      build.any_runners_available?
    end
  end

  describe '#artifacts?' do
    subject { build.artifacts? }

    context 'when new artifacts are used' do
      context 'artifacts archive does not exist' do
        let(:build) { create(:ci_build, pipeline: pipeline) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive exists' do
        let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

        it { is_expected.to be_truthy }

        context 'is expired' do
          let(:build) { create(:ci_build, :artifacts, :expired, pipeline: pipeline) }

          it { is_expected.to be_falsy }
        end
      end
    end
  end

  describe '#locked_artifacts?' do
    subject(:locked_artifacts) { build.locked_artifacts? }

    context 'when pipeline is artifacts_locked' do
      let(:pipeline) { create(:ci_pipeline, locked: :artifacts_locked) }

      context 'artifacts archive does not exist' do
        let(:build) { create(:ci_build, pipeline: pipeline) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive exists' do
        let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when pipeline is unlocked' do
      let(:pipeline) { create(:ci_pipeline, locked: :unlocked) }

      context 'artifacts archive does not exist' do
        let(:build) { create(:ci_build, pipeline: pipeline) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive exists' do
        let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#available_artifacts?' do
    let(:build) { create(:ci_build, pipeline: pipeline) }

    subject { build.available_artifacts? }

    context 'when artifacts are not expired' do
      before do
        build.artifacts_expire_at = Date.tomorrow
      end

      context 'when artifacts exist' do
        before do
          create(:ci_job_artifact, :archive, job: build)
        end

        it { is_expected.to be_truthy }
      end

      context 'when artifacts do not exist' do
        it { is_expected.to be_falsey }
      end
    end

    context 'when artifacts are expired' do
      before do
        build.artifacts_expire_at = Date.yesterday
      end

      context 'when artifacts are not locked' do
        before do
          build.pipeline.locked = :unlocked
        end

        it { is_expected.to be_falsey }
      end

      context 'when artifacts are locked' do
        before do
          build.pipeline.locked = :artifacts_locked
        end

        context 'when artifacts exist' do
          before do
            create(:ci_job_artifact, :archive, job: build)
          end

          it { is_expected.to be_truthy }
        end

        context 'when artifacts do not exist' do
          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#browsable_artifacts?' do
    subject { build.browsable_artifacts? }

    context 'artifacts metadata does exists' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#artifacts_public?' do
    subject { build.artifacts_public? }

    context 'artifacts with defaults - public' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it { is_expected.to be_truthy }
    end

    context 'non public artifacts' do
      let(:build) { create(:ci_build, :private_artifacts, pipeline: pipeline) }

      it { is_expected.to be_falsey }
    end

    context 'no artifacts' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#artifact_access_setting_in_config' do
    subject { build.artifact_access_setting_in_config }

    context 'artifacts with defaults' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it { is_expected.to eq(:public) }
    end

    context 'non public artifacts' do
      let(:build) { create(:ci_build, :with_private_artifacts_config, pipeline: pipeline) }

      it { is_expected.to eq(:private) }
    end

    context 'non public artifacts via access' do
      let(:build) { create(:ci_build, :with_developer_access_artifacts, pipeline: pipeline) }

      it { is_expected.to eq(:private) }
    end

    context 'non public artifacts via access as none' do
      let(:build) { create(:ci_build, :with_none_access_artifacts, pipeline: pipeline) }

      it { is_expected.to eq(:none) }
    end

    context 'public artifacts' do
      let(:build) { create(:ci_build, :with_public_artifacts_config, pipeline: pipeline) }

      it { is_expected.to eq(:public) }
    end

    context 'public artifacts via access' do
      let(:build) { create(:ci_build, :with_all_access_artifacts, pipeline: pipeline) }

      it { is_expected.to eq(:public) }
    end

    context 'no artifacts' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.to eq(:public) }
    end

    context 'when public and access are used together' do
      let(:build) { create(:ci_build, :with_access_and_public_setting, pipeline: pipeline) }

      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'artifacts:public and artifacts:access are mutually exclusive')
      end
    end
  end

  describe '#artifacts_expired?' do
    subject { build.artifacts_expired? }

    context 'is expired' do
      before do
        build.update!(artifacts_expire_at: Time.current - 7.days)
      end

      it { is_expected.to be_truthy }
    end

    context 'is not expired' do
      before do
        build.update!(artifacts_expire_at: Time.current + 7.days)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#artifacts_metadata?' do
    subject { build.artifacts_metadata? }

    context 'artifacts metadata does not exist' do
      it { is_expected.to be_falsy }
    end

    context 'artifacts archive is a zip file and metadata exists' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#artifacts_expire_in' do
    subject { build.artifacts_expire_in }

    it { is_expected.to be_nil }

    context 'when artifacts_expire_at is specified' do
      let(:expire_at) { Time.current + 7.days }

      before do
        build.artifacts_expire_at = expire_at
      end

      it { is_expected.to be_within(5).of(expire_at - Time.current) }
    end
  end

  describe '#artifacts_expire_in=' do
    subject { build.artifacts_expire_in }

    it 'when assigning valid duration' do
      build.artifacts_expire_in = '7 days'

      is_expected.to be_within(10).of(7.days.to_i)
    end

    it 'when assigning invalid duration' do
      expect { build.artifacts_expire_in = '7 elephants' }.to raise_error(ChronicDuration::DurationParseError)
      is_expected.to be_nil
    end

    it 'when resetting value' do
      build.artifacts_expire_in = nil

      is_expected.to be_nil
    end

    it 'when setting to 0' do
      build.artifacts_expire_in = '0'

      is_expected.to be_nil
    end
  end

  describe '#commit' do
    it 'returns commit pipeline has been created for' do
      expect(build.commit).to eq project.commit
    end
  end

  describe '#cache' do
    let(:options) do
      { cache: [{ key: "key", paths: ["public"], policy: "pull-push" }] }
    end

    let(:options_with_fallback_keys) do
      { cache: [
        { key: "key", paths: ["public"], policy: "pull-push", fallback_keys: %w[key1 key2] }
      ] }
    end

    subject { build.cache }

    context 'when build has cache' do
      before do
        allow(build).to receive(:options).and_return(options)
      end

      context 'when build has multiple caches' do
        let(:options) do
          { cache: [
            { key: "key", paths: ["public"], policy: "pull-push" },
            { key: "key2", paths: ["public"], policy: "pull-push" }
          ] }
        end

        let(:options_with_fallback_keys) do
          { cache: [
            { key: "key", paths: ["public"], policy: "pull-push", fallback_keys: %w[key3 key4] },
            { key: "key2", paths: ["public"], policy: "pull-push", fallback_keys: %w[key5 key6] }
          ] }
        end

        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(1)
        end

        it { is_expected.to match([a_hash_including(key: 'key-1-non_protected'), a_hash_including(key: 'key2-1-non_protected')]) }

        context 'when pipeline is on a protected ref' do
          before do
            allow(build.pipeline).to receive(:protected_ref?).and_return(true)
          end

          context 'without the `unprotect` option' do
            it do
              is_expected.to all(a_hash_including(key: a_string_matching(/-protected$/)))
            end

            context 'and the caches have fallback keys' do
              let(:options) { options_with_fallback_keys }

              it do
                is_expected.to all(a_hash_including({
                  key: a_string_matching(/-protected$/),
                  fallback_keys: array_including(a_string_matching(/-protected$/))
                }))
              end
            end
          end

          context 'and the cache has the `unprotect` option' do
            let(:options) do
              { cache: [
                { key: "key", paths: ["public"], policy: "pull-push", unprotect: true },
                { key: "key2", paths: ["public"], policy: "pull-push", unprotect: true }
              ] }
            end

            it do
              is_expected.to all(a_hash_including(key: a_string_matching(/-non_protected$/)))
            end

            context 'and the caches have fallback keys' do
              let(:options) do
                options_with_fallback_keys[:cache].each { |entry| entry[:unprotect] = true }
                options_with_fallback_keys
              end

              it do
                is_expected.to all(a_hash_including({
                  key: a_string_matching(/-non_protected$/),
                  fallback_keys: array_including(a_string_matching(/-non_protected$/))
                }))
              end
            end
          end
        end

        context 'when pipeline is not on a protected ref' do
          before do
            allow(build.pipeline).to receive(:protected_ref?).and_return(false)
          end

          it do
            is_expected.to all(a_hash_including(key: a_string_matching(/-non_protected$/)))
          end

          context 'and the caches have fallback keys' do
            let(:options) { options_with_fallback_keys }

            it do
              is_expected.to all(a_hash_including({
                key: a_string_matching(/-non_protected$/),
                fallback_keys: array_including(a_string_matching(/-non_protected$/))
              }))
            end
          end
        end

        context 'when separated caches are disabled' do
          before do
            allow_any_instance_of(Project).to receive(:ci_separated_caches).and_return(false)
          end

          context 'running on protected ref' do
            before do
              allow(build.pipeline).to receive(:protected_ref?).and_return(true)
            end

            it 'is expected to have no type suffix' do
              is_expected.to match([a_hash_including(key: 'key-1'), a_hash_including(key: 'key2-1')])
            end

            context 'and the caches have fallback keys' do
              let(:options) { options_with_fallback_keys }

              it do
                is_expected.to match([
                  a_hash_including({
                    key: 'key-1',
                    fallback_keys: %w[key3-1 key4-1]
                  }),
                  a_hash_including({
                    key: 'key2-1',
                    fallback_keys: %w[key5-1 key6-1]
                  })
                ])
              end
            end
          end

          context 'running on not protected ref' do
            before do
              allow(build.pipeline).to receive(:protected_ref?).and_return(false)
            end

            it 'is expected to have no type suffix' do
              is_expected.to match([a_hash_including(key: 'key-1'), a_hash_including(key: 'key2-1')])
            end

            context 'and the caches have fallback keys' do
              let(:options) { options_with_fallback_keys }

              it do
                is_expected.to match([
                  a_hash_including({
                    key: 'key-1',
                    fallback_keys: %w[key3-1 key4-1]
                  }),
                  a_hash_including({
                    key: 'key2-1',
                    fallback_keys: %w[key5-1 key6-1]
                  })
                ])
              end
            end
          end
        end
      end

      context 'when project has jobs_cache_index' do
        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(1)
        end

        it { is_expected.to be_an(Array).and all(include(key: a_string_matching(/^key-1-(?>protected|non_protected)/))) }

        context 'and the cache have fallback keys' do
          let(:options) { options_with_fallback_keys }

          it do
            is_expected.to be_an(Array).and all(include({
              key: a_string_matching(/^key-1-(?>protected|non_protected)/),
              fallback_keys: array_including(a_string_matching(/^key\d-1-(?>protected|non_protected)/))
            }))
          end
        end
      end

      context 'when project does not have jobs_cache_index' do
        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(nil)
        end

        it do
          is_expected.to eq(options[:cache].map { |entry| entry.merge(key: "#{entry[:key]}-non_protected") })
        end

        context 'and the cache have fallback keys' do
          let(:options) { options_with_fallback_keys }

          it do
            is_expected.to eq(
              options[:cache].map do |entry|
                entry[:key] = "#{entry[:key]}-non_protected"
                entry[:fallback_keys].map! { |key| "#{key}-non_protected" }

                entry
              end
            )
          end
        end
      end
    end

    context 'when build does not have cache' do
      before do
        allow(build).to receive(:options).and_return({})
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#fallback_cache_keys_defined?' do
    subject { build }

    it 'returns false when fallback keys are not defined' do
      expect(subject.fallback_cache_keys_defined?).to be false
    end

    context "with fallbacks keys" do
      before do
        allow(build).to receive(:options).and_return({
          cache: [{
            key: "key1",
            fallback_keys: %w[key2]
          }]
        })
      end

      it 'returns true when fallback keys are defined' do
        expect(subject.fallback_cache_keys_defined?).to be true
      end
    end
  end

  describe '#triggered_by?' do
    subject { build.triggered_by?(user) }

    context 'when user is owner' do
      let(:build) { create(:ci_build, pipeline: pipeline, user: user) }

      it { is_expected.to be_truthy }
    end

    context 'when user is not owner' do
      let(:another_user) { create(:user) }
      let(:build) { create(:ci_build, pipeline: pipeline, user: another_user) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#detailed_status' do
    it 'returns a detailed status' do
      expect(build.detailed_status(user))
        .to be_a Gitlab::Ci::Status::Build::Cancelable
    end
  end

  describe '#update_coverage' do
    context "regarding coverage_regex's value," do
      before do
        build.coverage_regex = '\(\d+.\d+\%\) covered'
        build.trace.set('Coverage 1033 / 1051 LOC (98.29%) covered')
      end

      it "saves the correct extracted coverage value" do
        expect(build.update_coverage).to be(true)
        expect(build.coverage).to eq(98.29)
      end
    end
  end

  describe '#trace' do
    subject { build.trace }

    it { is_expected.to be_a(Gitlab::Ci::Trace) }
  end

  describe '#has_trace?' do
    subject { build.has_trace? }

    it "expect to call exist? method" do
      expect_any_instance_of(Gitlab::Ci::Trace).to receive(:exist?)
        .and_return(true)

      is_expected.to be(true)
    end
  end

  describe '#has_live_trace?' do
    subject { build.has_live_trace? }

    let(:build) { create(:ci_build, :trace_live, pipeline: pipeline) }

    it { is_expected.to be_truthy }

    context 'when build does not have live trace' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#has_archived_trace?' do
    subject { build.has_archived_trace? }

    let(:build) { create(:ci_build, :trace_artifact, pipeline: pipeline) }

    it { is_expected.to be_truthy }

    context 'when build does not have archived trace' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#has_job_artifacts?' do
    subject { build.has_job_artifacts? }

    context 'when build has a job artifact' do
      let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#has_test_reports?' do
    subject { build.has_test_reports? }

    context 'when build has a test report' do
      let(:build) { create(:ci_build, :test_reports, pipeline: pipeline) }

      it { is_expected.to be_truthy }
    end

    context 'when build does not have a test report' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#hide_secrets' do
    let(:metrics) { spy('metrics') }
    let(:subject) { build.hide_secrets(data) }

    context 'hide runners token' do
      let(:data) { "new #{project.runners_token} data" }
      let(:allow_runner_registration_token) { true }

      it { is_expected.to match(/^new \[MASKED\]x+ data$/) }

      it 'increments trace mutation metric' do
        build.hide_secrets(data, metrics)

        expect(metrics)
          .to have_received(:increment_trace_operation)
          .with(operation: :mutated)
      end
    end

    context 'hide build token' do
      let_it_be(:build) { create(:ci_build, pipeline: pipeline) }

      before do
        stub_feature_flags(ci_job_token_jwt: token == :jwt)
      end

      where(:token) { [:database, :jwt] }

      with_them do
        let(:data) { "new #{build.token} data" }

        it { is_expected.to match(/^new \[MASKED\]x+ data$/) }

        it 'increments trace mutation metric' do
          build.hide_secrets(data, metrics)

          expect(metrics)
            .to have_received(:increment_trace_operation)
            .with(operation: :mutated)
        end
      end
    end

    context 'when build does not include secrets' do
      let(:data) { 'my build log' }

      it 'does not mutate trace' do
        trace = build.hide_secrets(data)

        expect(trace).to eq data
      end

      it 'does not increment trace mutation metric' do
        build.hide_secrets(data, metrics)

        expect(metrics)
          .not_to have_received(:increment_trace_operation)
          .with(operation: :mutated)
      end
    end
  end

  describe 'state transition metrics' do
    subject { build.send(event) }

    where(:state, :report_count, :trait) do
      :success! | 1 | :sast
      :cancel!  | 1 | :sast
      :drop!    | 2 | :multiple_report_artifacts
      :success! | 0 | :allowed_to_fail
      :skip!    | 0 | :pending
    end

    with_them do
      let(:build) { create(:ci_build, trait, pipeline: pipeline) }
      let(:event) { state }

      context "when transitioning to #{params[:state]}", :saas do
        it 'increments build_completed_report_type metric' do
          expect(
            ::Gitlab::Ci::Artifacts::Metrics
          ).to receive(
            :build_completed_report_type_counter
          ).exactly(report_count).times.and_call_original

          subject
        end
      end
    end
  end

  describe 'erasable build' do
    shared_examples 'erasable' do
      it 'removes artifact file' do
        expect(build.artifacts_file.present?).to be_falsy
      end

      it 'removes artifact metadata file' do
        expect(build.artifacts_metadata.present?).to be_falsy
      end

      it 'removes all job_artifacts' do
        expect(build.job_artifacts.count).to eq(0)
      end

      it 'erases build trace in trace file' do
        expect(build).not_to have_trace
      end

      it 'sets erased to true' do
        expect(build.erased?).to be true
      end

      it 'sets erase date' do
        expect(build.erased_at).not_to be_falsy
      end
    end

    context 'build is not erasable' do
      let!(:build) { create(:ci_build, pipeline: pipeline) }

      describe '#erasable?' do
        subject { build.erasable? }

        it { is_expected.to eq false }
      end
    end

    context 'build is erasable' do
      context 'new artifacts' do
        let!(:build) { create(:ci_build, :test_reports, :trace_artifact, :success, :artifacts, pipeline: pipeline) }

        describe '#erasable?' do
          subject { build.erasable? }

          it { is_expected.to be_truthy }
        end

        describe '#erased?' do
          let!(:build) { create(:ci_build, :trace_artifact, :success, :artifacts, pipeline: pipeline) }

          subject { build.erased? }

          context 'job has not been erased' do
            it { is_expected.to be_falsey }
          end

          context 'job has been erased' do
            before do
              build.update!(erased_at: 1.minute.ago)
            end

            it { is_expected.to be_truthy }
          end
        end
      end
    end
  end

  describe 'flags' do
    describe '#cancelable?' do
      subject { build }

      context 'when build is cancelable' do
        context 'when build is pending' do
          it { is_expected.to be_cancelable }
        end

        context 'when build is running' do
          before do
            build.run!
          end

          it { is_expected.to be_cancelable }
        end

        context 'when build is created' do
          let(:build) { create(:ci_build, :created, pipeline: pipeline) }

          it { is_expected.to be_cancelable }
        end

        context 'when build is waiting for resource' do
          let(:build) { create(:ci_build, :waiting_for_resource, pipeline: pipeline) }

          it { is_expected.to be_cancelable }
        end
      end

      context 'when build is not cancelable' do
        context 'when build is successful' do
          before do
            build.success!
          end

          it { is_expected.not_to be_cancelable }
        end

        context 'when build is failed' do
          before do
            build.drop!
          end

          it { is_expected.not_to be_cancelable }
        end
      end
    end

    describe '#action?' do
      before do
        build.update!(when: value)
      end

      subject { build.action? }

      context 'when is set to manual' do
        let(:value) { 'manual' }

        it { is_expected.to be_truthy }
      end

      context 'when is set to delayed' do
        let(:value) { 'delayed' }

        it { is_expected.to be_truthy }
      end

      context 'when set to something else' do
        let(:value) { 'something else' }

        it { is_expected.to be_falsey }
      end
    end

    describe '#can_auto_cancel_pipeline_on_job_failure?' do
      subject { build.can_auto_cancel_pipeline_on_job_failure? }

      before do
        allow(build).to receive(:auto_retry_expected?) { auto_retry_expected }
      end

      context 'when the job can be auto-retried' do
        let(:auto_retry_expected) { true }

        it { is_expected.to be false }
      end

      context 'when the job cannot be auto-retried' do
        let(:auto_retry_expected) { false }

        it { is_expected.to be true }
      end
    end
  end

  describe '#runner_manager' do
    let_it_be(:runner) { create(:ci_runner) }
    let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner) }
    let_it_be(:ci_stage) { create(:ci_stage) }
    let_it_be(:build) { create(:ci_build, runner_manager: runner_manager, ci_stage: ci_stage) }

    subject(:build_runner_manager) { described_class.find(build.id).runner_manager }

    it { is_expected.to eq(runner_manager) }
  end

  describe '#tag_list' do
    let_it_be(:build) { create(:ci_build, tag_list: ['tag'], pipeline: pipeline) }

    context 'when tags are preloaded' do
      it 'does not trigger queries' do
        build_with_tags = described_class.eager_load_tags.id_in([build]).to_a.first

        expect { build_with_tags.tag_list }.not_to exceed_all_query_limit(0)
        expect(build_with_tags.tag_list).to eq(['tag'])
      end
    end

    context 'when tags are not preloaded' do
      it { expect(described_class.find(build.id).tag_list).to eq(['tag']) }
    end
  end

  describe '#save_tags' do
    let(:build) { create(:ci_build, tag_list: ['tag'], pipeline: pipeline) }

    it 'saves tags' do
      build.save!

      expect(build.tags.count).to eq(1)
      expect(build.tags.first.name).to eq('tag')
      expect(build.taggings.count).to eq(1)
      expect(build.taggings.first.tag.name).to eq('tag')
    end

    it 'strips tags' do
      build.tag_list = ['       taga', 'tagb      ', '   tagc    ']

      build.save!
      expect(build.tags.map(&:name)).to match_array(%w[taga tagb tagc])
    end

    context 'with BulkInsertableTags.with_bulk_insert_tags' do
      it 'does not save_tags' do
        Ci::BulkInsertableTags.with_bulk_insert_tags do
          build.save!
        end

        expect(build.tags).to be_empty
        expect(build.taggings).to be_empty
      end
    end
  end

  describe '#has_tags?' do
    context 'when build has tags' do
      subject { create(:ci_build, tag_list: ['tag'], pipeline: pipeline) }

      it { is_expected.to have_tags }
    end

    context 'when build does not have tags' do
      subject { create(:ci_build, tag_list: [], pipeline: pipeline) }

      it { is_expected.not_to have_tags }
    end
  end

  describe 'build auto retry feature' do
    context 'with deployment job' do
      let(:build) do
        create(
          :ci_build,
          :deploy_to_production,
          :with_deployment,
          user: user,
          pipeline: pipeline,
          project: project
        )
      end

      before do
        project.add_developer(user)
        allow(build).to receive(:auto_retry_allowed?) { true }
      end

      it 'creates a deployment when a build is dropped' do
        expect { build.drop!(:script_failure) }.to change { Deployment.count }.by(1)

        retried_deployment = Deployment.last
        expect(build.deployment.environment).to eq(retried_deployment.environment)
        expect(build.deployment.ref).to eq(retried_deployment.ref)
        expect(build.deployment.sha).to eq(retried_deployment.sha)
        expect(build.deployment.tag).to eq(retried_deployment.tag)
        expect(build.deployment.user).to eq(retried_deployment.user)
        expect(build.deployment).to be_failed
        expect(retried_deployment).to be_created
      end
    end

    describe '#retries_count' do
      subject { create(:ci_build, name: 'test', pipeline: pipeline) }

      context 'when build has been retried several times' do
        before do
          create(:ci_build, :retried, name: 'test', pipeline: pipeline)
          create(:ci_build, :retried, name: 'test', pipeline: pipeline)
        end

        it 'reports a correct retry count value' do
          expect(subject.retries_count).to eq 2
        end
      end

      context 'when build has not been retried' do
        it 'returns zero' do
          expect(subject.retries_count).to eq 0
        end
      end
    end
  end

  describe '.keep_artifacts!' do
    let!(:build) { create(:ci_build, artifacts_expire_at: Time.current + 7.days, pipeline: pipeline) }
    let!(:builds_for_update) do
      described_class.where(id: create_list(:ci_build, 3, artifacts_expire_at: Time.current + 7.days, pipeline: pipeline).map(&:id))
    end

    it 'resets expire_at' do
      builds_for_update.keep_artifacts!

      builds_for_update.each do |build|
        expect(build.reload.artifacts_expire_at).to be_nil
      end
    end

    it 'does not reset expire_at for other builds' do
      builds_for_update.keep_artifacts!

      expect(build.reload.artifacts_expire_at).to be_present
    end

    context 'when having artifacts files' do
      let!(:artifact) { create(:ci_job_artifact, job: build, expire_in: '7 days') }
      let!(:artifacts_for_update) do
        builds_for_update.map do |build|
          create(:ci_job_artifact, job: build, expire_in: '7 days')
        end
      end

      it 'resets dependent objects' do
        builds_for_update.keep_artifacts!

        artifacts_for_update.each do |artifact|
          expect(artifact.reload.expire_at).to be_nil
        end
      end

      it 'does not reset dependent object for other builds' do
        builds_for_update.keep_artifacts!

        expect(artifact.reload.expire_at).to be_present
      end
    end
  end

  describe '#keep_artifacts!' do
    let(:build) { create(:ci_build, artifacts_expire_at: Time.current + 7.days, pipeline: pipeline) }

    subject { build.keep_artifacts! }

    it 'to reset expire_at' do
      subject

      expect(build.artifacts_expire_at).to be_nil
    end

    context 'when having artifacts files' do
      let!(:artifact) { create(:ci_job_artifact, job: build, expire_in: '7 days') }

      it 'to reset dependent objects' do
        subject

        expect(artifact.reload.expire_at).to be_nil
      end
    end
  end

  describe '#auto_retry_expected?' do
    subject { create(:ci_build, :failed, pipeline: pipeline) }

    context 'when build is failed and auto retry is configured' do
      before do
        allow(subject)
          .to receive(:auto_retry_allowed?)
          .and_return(true)
      end

      it 'expects auto-retry to happen' do
        expect(subject.auto_retry_expected?).to be true
      end
    end

    context 'when build failed by auto retry is not configured' do
      it 'does not expect auto-retry to happen' do
        expect(subject.auto_retry_expected?).to be false
      end
    end
  end

  describe '#artifact_for_type' do
    let(:build) { create(:ci_build) }
    let!(:archive) { create(:ci_job_artifact, :archive, job: build) }
    let!(:codequality) { create(:ci_job_artifact, :codequality, job: build) }
    let(:file_type) { :archive }

    subject { build.artifact_for_type(file_type) }

    it { is_expected.to eq(archive) }
  end

  describe '#merge_request' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    subject { pipeline.builds.take.merge_request }

    context 'on a branch pipeline' do
      let!(:pipeline) { create(:ci_pipeline, :with_job, project: project, ref: 'fix') }

      context 'with no merge request' do
        it { is_expected.to be_nil }
      end

      context 'with an open merge request from the same ref name' do
        let!(:merge_request) { create(:merge_request, source_project: project, source_branch: 'fix') }

        # If no diff exists, the pipeline commit was not part of the merge
        # request and may have simply incidentally used the same ref name.
        context 'without a merge request diff containing the pipeline commit' do
          it { is_expected.to be_nil }
        end

        # If the merge request was truly opened from the branch that the
        # pipeline ran on, that head sha will be present in a diff.
        context 'with a merge request diff containing the pipeline commit' do
          let!(:mr_diff) { create(:merge_request_diff, merge_request: merge_request) }
          let!(:mr_diff_commit) { create(:merge_request_diff_commit, sha: build.sha, merge_request_diff: mr_diff) }

          it { is_expected.to eq(merge_request) }
        end
      end

      context 'with multiple open merge requests' do
        let!(:merge_request)  { create(:merge_request, source_project: project, source_branch: 'fix') }
        let!(:mr_diff)        { create(:merge_request_diff, merge_request: merge_request) }
        let!(:mr_diff_commit) { create(:merge_request_diff_commit, sha: build.sha, merge_request_diff: mr_diff) }

        let!(:new_merge_request)  { create(:merge_request, source_project: project, source_branch: 'fix', target_branch: 'staging') }
        let!(:new_mr_diff)        { create(:merge_request_diff, merge_request: new_merge_request) }
        let!(:new_mr_diff_commit) { create(:merge_request_diff_commit, sha: build.sha, merge_request_diff: new_mr_diff) }

        it 'returns the first merge request' do
          expect(subject).to eq(merge_request)
        end
      end
    end

    context 'on a detached merged request pipeline' do
      let(:pipeline) do
        create(:ci_pipeline, :detached_merge_request_pipeline, :with_job, merge_request: merge_request)
      end

      it { is_expected.to eq(pipeline.merge_request) }
    end

    context 'on a legacy detached merged request pipeline' do
      let(:pipeline) do
        create(:ci_pipeline, :legacy_detached_merge_request_pipeline, :with_job, merge_request: merge_request)
      end

      it { is_expected.to eq(pipeline.merge_request) }
    end

    context 'on a pipeline for merged results' do
      let(:pipeline) { create(:ci_pipeline, :merged_result_pipeline, :with_job, merge_request: merge_request) }

      it { is_expected.to eq(pipeline.merge_request) }
    end
  end

  describe '#options' do
    let(:options) do
      {
        image: "image:1.0",
        services: ["postgres"],
        script: ["ls -a"]
      }
    end

    it 'contains options' do
      expect(build.options).to eq(options.symbolize_keys)
    end

    it 'allows to access with symbolized keys' do
      expect(build.options[:image]).to eq('image:1.0')
    end

    it 'rejects access with string keys' do
      expect(build.options['image']).to be_nil
    end

    it 'persist data in build metadata' do
      expect(build.metadata.read_attribute(:config_options)).to eq(options.symbolize_keys)
    end

    it 'does not persist data in build' do
      expect(build.read_attribute(:options)).to be_nil
    end

    context 'when options include artifacts:expose_as' do
      let(:build) { create(:ci_build, options: { artifacts: { expose_as: 'test' } }, pipeline: pipeline) }

      it 'saves the presence of expose_as into build metadata' do
        expect(build.metadata).to have_exposed_artifacts
      end
    end
  end

  describe '#other_scheduled_actions' do
    let(:build) { create(:ci_build, :scheduled, pipeline: pipeline) }

    subject { build.other_scheduled_actions }

    before do
      project.add_developer(user)
    end

    context "when other build's status is success" do
      let!(:other_build) { create(:ci_build, :schedulable, :success, pipeline: pipeline, name: 'other action') }

      it 'returns other actions' do
        is_expected.to contain_exactly(other_build)
      end
    end

    context "when other build's status is failed" do
      let!(:other_build) { create(:ci_build, :schedulable, :failed, pipeline: pipeline, name: 'other action') }

      it 'returns other actions' do
        is_expected.to contain_exactly(other_build)
      end
    end

    context "when other build's status is running" do
      let!(:other_build) { create(:ci_build, :schedulable, :running, pipeline: pipeline, name: 'other action') }

      it 'does not return other actions' do
        is_expected.to be_empty
      end
    end

    context "when other build's status is scheduled" do
      let!(:other_build) { create(:ci_build, :scheduled, pipeline: pipeline, name: 'other action') }

      it 'does not return other actions' do
        is_expected.to contain_exactly(other_build)
      end
    end
  end

  describe '#play' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }

    before do
      project.add_developer(user)
    end

    it 'enqueues the build' do
      expect(build.play(user)).to be_pending
    end
  end

  describe '#playable?' do
    context 'when build is a manual action' do
      context 'when build has been skipped' do
        subject { build_stubbed(:ci_build, :manual, status: :skipped, pipeline: pipeline) }

        it { is_expected.not_to be_playable }
      end

      context 'when build has been canceled' do
        subject { build_stubbed(:ci_build, :manual, status: :canceled, pipeline: pipeline) }

        it { is_expected.to be_playable }
      end

      context 'when build is successful' do
        subject { build_stubbed(:ci_build, :manual, status: :success, pipeline: pipeline) }

        it { is_expected.to be_playable }
      end

      context 'when build has failed' do
        subject { build_stubbed(:ci_build, :manual, status: :failed, pipeline: pipeline) }

        it { is_expected.to be_playable }
      end

      context 'when build is a manual untriggered action' do
        subject { build_stubbed(:ci_build, :manual, status: :manual, pipeline: pipeline) }

        it { is_expected.to be_playable }
      end

      context 'when build is a manual and degenerated' do
        subject { build_stubbed(:ci_build, :manual, :degenerated, status: :manual, pipeline: pipeline) }

        it { is_expected.not_to be_playable }
      end
    end

    context 'when build is scheduled' do
      subject { build_stubbed(:ci_build, :scheduled, pipeline: pipeline) }

      it { is_expected.to be_playable }
    end

    context 'when build is not a manual action' do
      subject { build_stubbed(:ci_build, :success, pipeline: pipeline) }

      it { is_expected.not_to be_playable }
    end
  end

  describe 'project settings' do
    describe '#allow_git_fetch' do
      it 'return project allow_git_fetch configuration' do
        expect(build.allow_git_fetch).to eq(project.build_allow_git_fetch)
      end
    end
  end

  describe '#project' do
    subject { build.project }

    it { is_expected.to eq(pipeline.project) }
  end

  describe '#project_id' do
    subject { build.project_id }

    it { is_expected.to eq(pipeline.project_id) }
  end

  describe '#project_name' do
    subject { build.project_name }

    it { is_expected.to eq(project.name) }
  end

  describe '#ref_slug' do
    where(:ref, :slug) do
      'master'             | 'master'
      '1-foo'              | '1-foo'
      'fix/1-foo'          | 'fix-1-foo'
      'fix-1-foo'          | 'fix-1-foo'
      ('a' * 63)             | ('a' * 63)
      ('a' * 64)             | ('a' * 63)
      'FOO' | 'foo'
      ('-' + ('a' * 61) + '-') | ('a' * 61)
      ('-' + ('a' * 62) + '-') | ('a' * 62)
      ('-' + ('a' * 63) + '-') | ('a' * 62)
      (('a' * 62) + ' ')       | ('a' * 62)
    end

    with_them do
      it "transforms ref to slug" do
        build.ref = ref

        expect(build.ref_slug).to eq(slug)
      end
    end
  end

  describe '#repo_url' do
    subject { build.repo_url }

    context 'when token is set' do
      before do
        allow(build).to receive(:token).and_return('my-token')
      end

      it { is_expected.to be_a(String) }
      it { is_expected.to end_with(".git") }
      it { is_expected.to start_with(project.web_url[0..6]) }
      it { is_expected.to include(build.token) }
      it { is_expected.to include('gitlab-ci-token') }
      it { is_expected.to include(project.web_url[7..]) }
    end

    context 'when token is empty' do
      before do
        allow(build).to receive(:token).and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#stuck?' do
    subject { build.stuck? }

    context "when commit_status.status is pending" do
      before do
        build.status = 'pending'
      end

      it { is_expected.to be_truthy }

      context "and there is a project runner" do
        let!(:runner) { create(:ci_runner, :project, projects: [build.project], contacted_at: 1.second.ago) }

        it { is_expected.to be_falsey }
      end
    end

    %w[success failed canceled running].each do |state|
      context "when commit_status.status is #{state}" do
        before do
          build.status = state
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#has_expired_locked_archive_artifacts?' do
    subject { build.has_expired_locked_archive_artifacts? }

    context 'when build does not have artifacts' do
      it { is_expected.to eq(nil) }
    end

    context 'when build has artifacts' do
      before do
        create(:ci_job_artifact, :archive, job: build)
      end

      context 'when artifacts are unlocked' do
        before do
          build.pipeline.unlocked!
        end

        it { is_expected.to eq(false) }
      end

      context 'when artifacts are locked' do
        before do
          build.pipeline.artifacts_locked!
        end

        context 'when artifacts do not expire' do
          it { is_expected.to be_falsey }
        end

        context 'when artifacts expire in the future' do
          before do
            build.update!(artifacts_expire_at: 1.day.from_now)
          end

          it { is_expected.to eq(false) }
        end

        context 'when artifacts expired in the past' do
          before do
            build.update!(artifacts_expire_at: 1.day.ago)
          end

          it { is_expected.to eq(true) }
        end
      end
    end
  end

  describe '#has_expiring_archive_artifacts?' do
    context 'when artifacts have expiration date set' do
      before do
        build.update!(artifacts_expire_at: 1.day.from_now)
      end

      context 'and job artifacts archive record exists' do
        let!(:archive) { create(:ci_job_artifact, :archive, job: build) }

        it 'has expiring artifacts' do
          expect(build).to have_expiring_archive_artifacts
        end
      end

      context 'and job artifacts archive record does not exist' do
        it 'does not have expiring artifacts' do
          expect(build).not_to have_expiring_archive_artifacts
        end
      end
    end

    context 'when artifacts do not have expiration date set' do
      before do
        build.update!(artifacts_expire_at: nil)
      end

      it 'does not have expiring artifacts' do
        expect(build).not_to have_expiring_archive_artifacts
      end
    end
  end

  describe '#variables' do
    let(:container_registry_enabled) { false }

    before do
      stub_container_registry_config(enabled: container_registry_enabled, host_port: 'registry.example.com')
      stub_config(dependency_proxy: { enabled: true })
    end

    subject { build.variables }

    context 'returns variables' do
      let(:pages_hostname) { "#{project.namespace.path}.example.com" }
      let(:pages_url) { "http://#{pages_hostname}/#{project.path}" }
      let(:predefined_variables) do
        [
          { key: 'CI_PIPELINE_ID', value: pipeline.id.to_s, public: true, masked: false },
          { key: 'CI_PIPELINE_URL', value: project.web_url + "/-/pipelines/#{pipeline.id}", public: true, masked: false },
          { key: 'CI_JOB_ID', value: build.id.to_s, public: true, masked: false },
          { key: 'CI_JOB_URL', value: project.web_url + "/-/jobs/#{build.id}", public: true, masked: false },
          { key: 'CI_JOB_TOKEN', value: 'my-token', public: false, masked: true },
          { key: 'CI_JOB_STARTED_AT', value: build.started_at&.iso8601, public: true, masked: false },
          { key: 'CI_REGISTRY_USER', value: 'gitlab-ci-token', public: true, masked: false },
          { key: 'CI_REGISTRY_PASSWORD', value: 'my-token', public: false, masked: true },
          { key: 'CI_REPOSITORY_URL', value: build.repo_url, public: false, masked: false },
          { key: 'CI_DEPENDENCY_PROXY_USER', value: 'gitlab-ci-token', public: true, masked: false },
          { key: 'CI_DEPENDENCY_PROXY_PASSWORD', value: 'my-token', public: false, masked: true },
          { key: 'CI_JOB_NAME', value: 'test', public: true, masked: false },
          { key: 'CI_JOB_NAME_SLUG', value: 'test', public: true, masked: false },
          { key: 'CI_JOB_STAGE', value: 'test', public: true, masked: false },
          { key: 'CI_NODE_TOTAL', value: '1', public: true, masked: false },
          { key: 'CI', value: 'true', public: true, masked: false },
          { key: 'GITLAB_CI', value: 'true', public: true, masked: false },
          { key: 'CI_SERVER_FQDN', value: Gitlab.config.gitlab_ci.server_fqdn, public: true, masked: false },
          { key: 'CI_SERVER_URL', value: Gitlab.config.gitlab.url, public: true, masked: false },
          { key: 'CI_SERVER_HOST', value: Gitlab.config.gitlab.host, public: true, masked: false },
          { key: 'CI_SERVER_PORT', value: Gitlab.config.gitlab.port.to_s, public: true, masked: false },
          { key: 'CI_SERVER_PROTOCOL', value: Gitlab.config.gitlab.protocol, public: true, masked: false },
          { key: 'CI_SERVER_SHELL_SSH_HOST', value: Gitlab.config.gitlab_shell.ssh_host.to_s, public: true, masked: false },
          { key: 'CI_SERVER_SHELL_SSH_PORT', value: Gitlab.config.gitlab_shell.ssh_port.to_s, public: true, masked: false },
          { key: 'CI_SERVER_NAME', value: 'GitLab', public: true, masked: false },
          { key: 'CI_SERVER_VERSION', value: Gitlab::VERSION, public: true, masked: false },
          { key: 'CI_SERVER_VERSION_MAJOR', value: Gitlab.version_info.major.to_s, public: true, masked: false },
          { key: 'CI_SERVER_VERSION_MINOR', value: Gitlab.version_info.minor.to_s, public: true, masked: false },
          { key: 'CI_SERVER_VERSION_PATCH', value: Gitlab.version_info.patch.to_s, public: true, masked: false },
          { key: 'CI_SERVER_REVISION', value: Gitlab.revision, public: true, masked: false },
          { key: 'GITLAB_FEATURES', value: project.licensed_features.join(','), public: true, masked: false },
          { key: 'CI_PROJECT_ID', value: project.id.to_s, public: true, masked: false },
          { key: 'CI_PROJECT_NAME', value: project.path, public: true, masked: false },
          { key: 'CI_PROJECT_TITLE', value: project.title, public: true, masked: false },
          { key: 'CI_PROJECT_DESCRIPTION', value: project.description, public: true, masked: false },
          { key: 'CI_PROJECT_PATH', value: project.full_path, public: true, masked: false },
          { key: 'CI_PROJECT_PATH_SLUG', value: project.full_path_slug, public: true, masked: false },
          { key: 'CI_PROJECT_NAMESPACE', value: project.namespace.full_path, public: true, masked: false },
          { key: 'CI_PROJECT_NAMESPACE_ID', value: project.namespace.id.to_s, public: true, masked: false },
          { key: 'CI_PROJECT_ROOT_NAMESPACE', value: project.namespace.root_ancestor.path, public: true, masked: false },
          { key: 'CI_PROJECT_URL', value: project.web_url, public: true, masked: false },
          { key: 'CI_PROJECT_VISIBILITY', value: 'private', public: true, masked: false },
          { key: 'CI_PROJECT_REPOSITORY_LANGUAGES', value: project.repository_languages.map(&:name).join(',').downcase, public: true, masked: false },
          { key: 'CI_PROJECT_CLASSIFICATION_LABEL', value: project.external_authorization_classification_label, public: true, masked: false },
          { key: 'CI_DEFAULT_BRANCH', value: project.default_branch, public: true, masked: false },
          { key: 'CI_CONFIG_PATH', value: project.ci_config_path_or_default, public: true, masked: false },
          { key: 'CI_PAGES_DOMAIN', value: Gitlab.config.pages.host, public: true, masked: false },
          { key: 'CI_DEPENDENCY_PROXY_SERVER', value: Gitlab.host_with_port, public: true, masked: false },
          { key: 'CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX',
            value: "#{Gitlab.host_with_port}/#{project.namespace.root_ancestor.path.downcase}#{DependencyProxy::URL_SUFFIX}",
            public: true,
            masked: false },
          { key: 'CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX',
            value: "#{Gitlab.host_with_port}/#{project.namespace.full_path.downcase}#{DependencyProxy::URL_SUFFIX}",
            public: true,
            masked: false },
          { key: 'CI_API_V4_URL', value: 'http://localhost/api/v4', public: true, masked: false },
          { key: 'CI_API_GRAPHQL_URL', value: 'http://localhost/api/graphql', public: true, masked: false },
          { key: 'CI_TEMPLATE_REGISTRY_HOST', value: template_registry_host, public: true, masked: false },
          { key: 'CI_PIPELINE_IID', value: pipeline.iid.to_s, public: true, masked: false },
          { key: 'CI_PIPELINE_SOURCE', value: pipeline.source, public: true, masked: false },
          { key: 'CI_PIPELINE_CREATED_AT', value: pipeline.created_at.iso8601, public: true, masked: false },
          { key: 'CI_PIPELINE_NAME', value: pipeline.name, public: true, masked: false },
          { key: 'CI_COMMIT_SHA', value: build.sha, public: true, masked: false },
          { key: 'CI_COMMIT_SHORT_SHA', value: build.short_sha, public: true, masked: false },
          { key: 'CI_COMMIT_BEFORE_SHA', value: build.before_sha, public: true, masked: false },
          { key: 'CI_COMMIT_REF_NAME', value: build.ref, public: true, masked: false },
          { key: 'CI_COMMIT_REF_SLUG', value: build.ref_slug, public: true, masked: false },
          { key: 'CI_COMMIT_BRANCH', value: build.ref, public: true, masked: false },
          { key: 'CI_COMMIT_MESSAGE', value: pipeline.git_commit_message, public: true, masked: false },
          { key: 'CI_COMMIT_TITLE', value: pipeline.git_commit_title, public: true, masked: false },
          { key: 'CI_COMMIT_DESCRIPTION', value: pipeline.git_commit_description, public: true, masked: false },
          { key: 'CI_COMMIT_REF_PROTECTED', value: (!!pipeline.protected_ref?).to_s, public: true, masked: false },
          { key: 'CI_COMMIT_TIMESTAMP', value: pipeline.git_commit_timestamp, public: true, masked: false },
          { key: 'CI_COMMIT_AUTHOR', value: pipeline.git_author_full_text, public: true, masked: false },
          { key: 'CI_PAGES_HOSTNAME', value: pages_hostname, public: true, masked: false },
          { key: 'CI_PAGES_URL', value: pages_url, public: true, masked: false }
        ]
      end

      before do
        allow(Gitlab::Ci::Jwt).to receive(:for_build).and_return('ci.job.jwt')
        allow(Gitlab::Ci::JwtV2).to receive(:for_build).and_return('ci.job.jwtv2')
        allow(build).to receive(:token).and_return('my-token')
        build.yaml_variables = []
      end

      it { is_expected.to be_instance_of(Gitlab::Ci::Variables::Collection) }

      it { expect(subject.to_runner_variables).to eq(predefined_variables) }

      it 'excludes variables that require an environment or user' do
        environment_based_variables_collection = subject.filter do |variable|
          %w[
            YAML_VARIABLE CI_ENVIRONMENT_NAME CI_ENVIRONMENT_SLUG
            CI_ENVIRONMENT_ACTION CI_ENVIRONMENT_URL
          ].include?(variable[:key])
        end

        expect(environment_based_variables_collection).to be_empty
      end

      describe 'variables ordering' do
        context 'when variables hierarchy is stubbed' do
          let(:build_pre_var) { { key: 'build', value: 'value', public: true, masked: false } }
          let(:project_pre_var) { { key: 'project', value: 'value', public: true, masked: false } }
          let(:pipeline_pre_var) { { key: 'pipeline', value: 'value', public: true, masked: false } }
          let(:build_yaml_var) { { key: 'yaml', value: 'value', public: true, masked: false } }
          let(:dependency_proxy_var) { { key: 'dependency_proxy', value: 'value', public: true, masked: false } }
          let(:job_jwt_var) { { key: 'CI_JOB_JWT', value: 'ci.job.jwt', public: false, masked: true } }
          let(:job_jwt_var_v1) { { key: 'CI_JOB_JWT_V1', value: 'ci.job.jwt', public: false, masked: true } }
          let(:job_jwt_var_v2) { { key: 'CI_JOB_JWT_V2', value: 'ci.job.jwtv2', public: false, masked: true } }
          let(:job_dependency_var) { { key: 'job_dependency', value: 'value', public: true, masked: false } }

          before do
            allow_next_instance_of(Gitlab::Ci::Variables::Builder) do |builder|
              pipeline_variables_builder = double(
                ::Gitlab::Ci::Variables::Builder::Pipeline,
                predefined_variables: [pipeline_pre_var]
              )

              allow(builder).to receive(:predefined_variables) { [build_pre_var] }
              allow(builder).to receive(:pipeline_variables_builder) { pipeline_variables_builder }
            end

            allow(build).to receive(:yaml_variables) { [build_yaml_var] }
            allow(build).to receive(:persisted_variables) { [] }
            allow(build).to receive(:job_jwt_variables) { [job_jwt_var] }
            allow(build).to receive(:dependency_variables) { [job_dependency_var] }
            allow(build).to receive(:dependency_proxy_variables) { [dependency_proxy_var] }

            allow(build.pipeline.project)
              .to receive(:predefined_variables) { [project_pre_var] }

            project.variables.create!(key: 'secret', value: 'value')
          end

          it 'returns variables in order depending on resource hierarchy' do
            expect(subject.to_runner_variables).to eq(
              [dependency_proxy_var,
               job_jwt_var,
               build_pre_var,
               project_pre_var,
               pipeline_pre_var,
               build_yaml_var,
               job_dependency_var,
               { key: 'secret', value: 'value', public: false, masked: false },
               { key: "CI_PAGES_HOSTNAME", value: pages_hostname, masked: false, public: true },
               { key: "CI_PAGES_URL", value: pages_url, masked: false, public: true }])
          end
        end

        context 'when build has environment and user-provided variables' do
          let(:expected_variables) do
            predefined_variables.map { |variable| variable.fetch(:key) }
          end

          before do
            create(:environment, project: build.project, name: 'staging')

            build.yaml_variables = [{ key: 'YAML_VARIABLE', value: 'var', public: true }]
            build.environment = 'staging'

            insert_expected_predefined_variables(
              [
                { key: 'CI_ENVIRONMENT_NAME', value: 'staging', public: true, masked: false },
                { key: 'CI_ENVIRONMENT_ACTION', value: 'start', public: true, masked: false },
                { key: 'CI_ENVIRONMENT_TIER', value: 'staging', public: true, masked: false },
                { key: 'CI_ENVIRONMENT_URL', value: 'https://gitlab.com', public: true, masked: false }
              ],
              after: 'CI_NODE_TOTAL')

            insert_expected_predefined_variables(
              [
                { key: 'YAML_VARIABLE', value: 'staging', public: true, masked: false },
                { key: 'CI_ENVIRONMENT_SLUG', value: 'start', public: true, masked: false },
                { key: 'CI_ENVIRONMENT_URL', value: 'https://gitlab.com', public: true, masked: false }
              ],
              after: 'CI_COMMIT_AUTHOR')
          end

          it 'matches explicit variables ordering' do
            received_variables = subject.map { |variable| variable[:key] }

            expect(received_variables).to eq(expected_variables)
          end

          describe 'CI_ENVIRONMENT_ACTION' do
            let(:enviroment_action_variable) { subject.find { |variable| variable[:key] == 'CI_ENVIRONMENT_ACTION' } }

            shared_examples 'defaults value' do
              it 'value matches start' do
                expect(enviroment_action_variable[:value]).to eq('start')
              end
            end

            it_behaves_like 'defaults value'

            context 'when options is set' do
              before do
                build.update!(options: options)
              end

              context 'when options is empty' do
                let(:options) { {} }

                it_behaves_like 'defaults value'
              end

              context 'when options is nil' do
                let(:options) { nil }

                it_behaves_like 'defaults value'
              end

              context 'when options environment is specified' do
                let(:options) { { environment: {} } }

                it_behaves_like 'defaults value'
              end

              context 'when options environment action specified' do
                let(:options) { { environment: { action: 'stop' } } }

                it 'matches the specified action' do
                  expect(enviroment_action_variable[:value]).to eq('stop')
                end
              end
            end
          end
        end
      end

      context 'when the build has ID tokens' do
        before do
          build.update!(
            id_tokens: { 'TEST_ID_TOKEN' => { 'aud' => 'https://client.test' } }
          )
        end

        it 'includes the tokens and excludes the predefined JWT variables' do
          runner_vars = subject.to_runner_variables.pluck(:key)

          expect(runner_vars).to include('TEST_ID_TOKEN')
          expect(runner_vars).not_to include('CI_JOB_JWT')
          expect(runner_vars).not_to include('CI_JOB_JWT_V1')
          expect(runner_vars).not_to include('CI_JOB_JWT_V2')
        end
      end

      def insert_expected_predefined_variables(variables, after:)
        index = predefined_variables.index { |h| h[:key] == after }
        predefined_variables.insert(index + 1, *variables)
      end
    end

    context 'when build has user' do
      let(:user_variables) do
        [
          { key: 'GITLAB_USER_ID', value: user.id.to_s, public: true, masked: false },
          { key: 'GITLAB_USER_EMAIL', value: user.email, public: true, masked: false },
          { key: 'GITLAB_USER_LOGIN', value: user.username, public: true, masked: false },
          { key: 'GITLAB_USER_NAME', value: user.name, public: true, masked: false }
        ]
      end

      before do
        build.update!(user: user)
      end

      it { user_variables.each { |v| is_expected.to include(v) } }
    end

    context 'when build belongs to a pipeline for merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline, source_branch: 'improve/awesome') }
      let(:pipeline) { merge_request.all_pipelines.first }
      let(:build) { create(:ci_build, ref: pipeline.ref, pipeline: pipeline) }

      it 'returns values based on source ref' do
        is_expected.to include(
          { key: 'CI_COMMIT_REF_NAME', value: 'improve/awesome', public: true, masked: false },
          { key: 'CI_COMMIT_REF_SLUG', value: 'improve-awesome', public: true, masked: false }
        )
      end
    end

    context 'when build has an environment' do
      let(:expected_environment_variables) do
        [
          { key: 'CI_ENVIRONMENT_NAME', value: 'production', public: true, masked: false },
          { key: 'CI_ENVIRONMENT_ACTION', value: 'start', public: true, masked: false },
          { key: 'CI_ENVIRONMENT_TIER', value: 'production', public: true, masked: false },
          { key: 'CI_ENVIRONMENT_URL', value: 'http://prd.example.com/$CI_JOB_NAME', public: true, masked: false }
        ]
      end

      let(:build) { create(:ci_build, :with_deployment, :deploy_to_production, ref: pipeline.ref, pipeline: pipeline) }

      shared_examples 'containing environment variables' do
        it { is_expected.to include(*expected_environment_variables) }
      end

      context 'when no URL was set' do
        before do
          build.update!(options: { environment: { url: nil } })
          build.persisted_environment.update!(external_url: nil)
          expected_environment_variables.delete_if { |var| var[:key] == 'CI_ENVIRONMENT_URL' }
        end

        it_behaves_like 'containing environment variables'

        it 'does not have CI_ENVIRONMENT_URL' do
          keys = subject.pluck(:key)

          expect(keys).not_to include('CI_ENVIRONMENT_URL')
        end
      end

      context 'when environment is created dynamically' do
        let(:build) { create(:ci_build, :with_deployment, :start_review_app, ref: pipeline.ref, pipeline: pipeline) }

        let(:expected_environment_variables) do
          [
            { key: 'CI_ENVIRONMENT_NAME', value: 'review/master', public: true, masked: false },
            { key: 'CI_ENVIRONMENT_ACTION', value: 'start', public: true, masked: false },
            { key: 'CI_ENVIRONMENT_TIER', value: 'development', public: true, masked: false },
            { key: 'CI_ENVIRONMENT_URL', value: 'http://staging.example.com/$CI_JOB_NAME', public: true, masked: false }
          ]
        end

        it_behaves_like 'containing environment variables'
      end

      context 'when an URL was set' do
        let(:url) { 'http://host/test' }

        before do
          expected_environment_variables.find { |var| var[:key] == 'CI_ENVIRONMENT_URL' }[:value] = url
        end

        context 'when the URL was set from the job' do
          before do
            build.update!(options: { environment: { url: url } })
          end

          it_behaves_like 'containing environment variables'

          context 'when variables are used in the URL, it does not expand' do
            let(:url) { 'http://$CI_PROJECT_NAME-$CI_ENVIRONMENT_SLUG' }

            it_behaves_like 'containing environment variables'

            it 'puts $CI_ENVIRONMENT_URL in the last so all other variables are available to be used when runners are trying to expand it' do
              ci_env_url = subject.to_runner_variables.find { |var| var[:key] == 'CI_ENVIRONMENT_URL' }

              expect(ci_env_url).to eq(expected_environment_variables.last)
            end
          end
        end

        context 'when the URL was not set from the job, but environment' do
          before do
            build.update!(options: { environment: { url: nil } })
            build.persisted_environment.update!(external_url: url)
          end

          it_behaves_like 'containing environment variables'
        end
      end

      context 'when environment_tier is updated in options' do
        before do
          build.update!(options: { environment: { name: 'production', deployment_tier: 'development' } })
        end

        it 'uses tier from options' do
          is_expected.to include({ key: 'CI_ENVIRONMENT_TIER', value: 'development', public: true, masked: false })
        end
      end

      context 'when project has an environment specific variable' do
        let(:environment_specific_variable) do
          { key: 'MY_STAGING_ONLY_VARIABLE', value: 'environment_specific_variable', public: false, masked: false }
        end

        before do
          create(:ci_variable, environment_specific_variable.slice(:key, :value)
            .merge(project: project, environment_scope: 'stag*'))
        end

        it_behaves_like 'containing environment variables'

        context 'when environment scope does not match build environment' do
          it { is_expected.not_to include(environment_specific_variable) }
        end

        context 'when environment scope matches build environment' do
          let(:build) { create(:ci_build, :with_deployment, :start_staging, ref: pipeline.ref, pipeline: pipeline) }

          it { is_expected.to include(environment_specific_variable) }
        end
      end
    end

    context 'when build started manually' do
      before do
        build.update!(when: :manual)
      end

      let(:manual_variable) do
        { key: 'CI_JOB_MANUAL', value: 'true', public: true, masked: false }
      end

      it { is_expected.to include(manual_variable) }
    end

    context 'when job variable is defined' do
      let(:job_variable) { { key: 'first', value: 'first', public: false, masked: false } }

      before do
        create(:ci_job_variable, job_variable.slice(:key, :value).merge(job: build))
      end

      it { is_expected.to include(job_variable) }
    end

    context 'when build is for branch' do
      let(:branch_variable) do
        { key: 'CI_COMMIT_BRANCH', value: 'master', public: true, masked: false }
      end

      before do
        build.update!(tag: false)
        pipeline.update!(tag: false)
      end

      it { is_expected.to include(branch_variable) }
    end

    context 'when build is for tag' do
      let(:tag_name) { project.repository.tags.first.name }
      let(:tag_message) { project.repository.tags.first.message }

      let!(:pipeline) do
        create(
          :ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: tag_name,
          status: 'success'
        )
      end

      let!(:build) { create(:ci_build, pipeline: pipeline, ref: tag_name) }

      let(:tag_variable) do
        { key: 'CI_COMMIT_TAG', value: tag_name, public: true, masked: false }
      end

      let(:tag_message_variable) do
        { key: 'CI_COMMIT_TAG_MESSAGE', value: tag_message, public: true, masked: false }
      end

      before do
        build.update!(tag: true)
        pipeline.update!(tag: true)
      end

      it do
        build.reload

        expect(subject).to include(tag_variable, tag_message_variable)
      end
    end

    context 'when CI variable is defined' do
      let(:ci_variable) do
        { key: 'SECRET_KEY', value: 'secret_value', public: false, masked: false }
      end

      before do
        create(:ci_variable, ci_variable.slice(:key, :value).merge(project: project))
      end

      it { is_expected.to include(ci_variable) }
    end

    context 'when protected variable is defined' do
      let(:ref) { Gitlab::Git::BRANCH_REF_PREFIX + build.ref }

      let(:protected_variable) do
        { key: 'PROTECTED_KEY', value: 'protected_value', public: false, masked: false }
      end

      before do
        create(:ci_variable, :protected, protected_variable.slice(:key, :value).merge(project: project))
      end

      context 'when the branch is protected' do
        before do
          allow(build.pipeline.project).to receive(:protected_for?).with(ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the tag is protected' do
        before do
          allow(build.pipeline.project).to receive(:protected_for?).with(ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the ref is not protected' do
        it { is_expected.not_to include(protected_variable) }
      end
    end

    context 'when group CI variable is defined' do
      let(:ci_variable) do
        { key: 'SECRET_KEY', value: 'secret_value', public: false, masked: false }
      end

      before do
        create(:ci_group_variable, ci_variable.slice(:key, :value).merge(group: group))
      end

      it { is_expected.to include(ci_variable) }
    end

    context 'when group protected variable is defined' do
      let(:ref) { Gitlab::Git::BRANCH_REF_PREFIX + build.ref }

      let(:protected_variable) do
        { key: 'PROTECTED_KEY', value: 'protected_value', public: false, masked: false }
      end

      before do
        create(:ci_group_variable, :protected, protected_variable.slice(:key, :value).merge(group: group))
      end

      context 'when the branch is protected' do
        before do
          allow(build.pipeline.project).to receive(:protected_for?).with(ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the tag is protected' do
        before do
          allow(build.pipeline.project).to receive(:protected_for?).with(ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the ref is not protected' do
        before do
          build.update_column(:ref, 'some/feature')
        end

        it { is_expected.not_to include(protected_variable) }
      end
    end

    context 'when pipeline has a variable' do
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline) }

      it { is_expected.to include(key: pipeline_variable.key, value: pipeline_variable.value, public: false, masked: false) }
    end

    context 'when a job was triggered by a pipeline schedule' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

      let!(:pipeline_schedule_variable) do
        create(:ci_pipeline_schedule_variable, key: 'SCHEDULE_VARIABLE_KEY', pipeline_schedule: pipeline_schedule)
      end

      before do
        pipeline_schedule.pipelines << pipeline.reload
        pipeline_schedule.reload
      end

      it { is_expected.to include(key: pipeline_schedule_variable.key, value: pipeline_schedule_variable.value, public: false, masked: false) }
      it { is_expected.to include(key: 'CI_PIPELINE_SCHEDULE_DESCRIPTION', value: pipeline_schedule.description, public: true, masked: false) }
    end

    context 'when container registry is enabled' do
      let_it_be_with_reload(:project) { create(:project, :public, :repository, group: group) }

      let_it_be_with_reload(:pipeline) do
        create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch, status: 'success')
      end

      let_it_be_with_refind(:build) { create(:ci_build, pipeline: pipeline) }

      let(:container_registry_enabled) { true }
      let(:ci_registry) do
        { key: 'CI_REGISTRY', value: 'registry.example.com', public: true, masked: false }
      end

      let(:ci_registry_image) do
        { key: 'CI_REGISTRY_IMAGE', value: project.container_registry_url, public: true, masked: false }
      end

      context 'and is disabled for project' do
        before do
          project.project_feature.update_column(:container_registry_access_level, ProjectFeature::DISABLED)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.not_to include(ci_registry_image) }
      end

      context 'and is enabled for project' do
        before do
          project.project_feature.update_column(:container_registry_access_level, ProjectFeature::ENABLED)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.to include(ci_registry_image) }
      end

      context 'and is private for project' do
        before do
          project.project_feature.update_column(:container_registry_access_level, ProjectFeature::PRIVATE)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.to include(ci_registry_image) }
      end
    end

    context 'when runner is assigned to build' do
      let(:runner) { create(:ci_runner, description: 'description', tag_list: %w[docker linux]) }
      let(:expected_tags_value) { %w[docker linux].to_s }

      before do
        build.update!(runner: runner)
      end

      it { is_expected.to include({ key: 'CI_RUNNER_ID', value: runner.id.to_s, public: true, masked: false }) }
      it { is_expected.to include({ key: 'CI_RUNNER_DESCRIPTION', value: 'description', public: true, masked: false }) }
      it { is_expected.to include({ key: 'CI_RUNNER_TAGS', value: expected_tags_value, public: true, masked: false }) }

      context 'when the tags are preloaded' do
        subject { described_class.preload(:tags).find(build.id).variables }

        it { is_expected.to include({ key: 'CI_RUNNER_TAGS', value: expected_tags_value, public: true, masked: false }) }
      end
    end

    context 'when build is for a deployment' do
      let(:deployment_variable) { { key: 'KUBERNETES_TOKEN', value: 'TOKEN', public: false, masked: false } }

      before do
        build.environment = 'production'

        allow_any_instance_of(Project)
          .to receive(:deployment_variables)
          .and_return([deployment_variable])
      end

      it { is_expected.to include(deployment_variable) }
    end

    context 'when project has default CI config path' do
      let(:ci_config_path) { { key: 'CI_CONFIG_PATH', value: '.gitlab-ci.yml', public: true, masked: false } }

      it { is_expected.to include(ci_config_path) }
    end

    context 'when project has custom CI config path' do
      let(:ci_config_path) { { key: 'CI_CONFIG_PATH', value: 'custom', public: true, masked: false } }

      before do
        project.update!(ci_config_path: 'custom')
      end

      it { is_expected.to include(ci_config_path) }
    end

    context 'when pipeline variable overrides build variable' do
      let(:build) do
        create(:ci_build, pipeline: pipeline, ci_stage: pipeline.stages.first, yaml_variables: [{ key: 'MYVAR', value: 'myvar', public: true }])
      end

      before do
        pipeline.variables.build(key: 'MYVAR', value: 'pipeline value')
      end

      it 'overrides YAML variable using a pipeline variable' do
        variables = subject.to_runner_variables.reverse.uniq { |variable| variable[:key] }.reverse

        expect(variables)
          .not_to include(key: 'MYVAR', value: 'myvar', public: true, masked: false)
        expect(variables)
          .to include(key: 'MYVAR', value: 'pipeline value', public: false, masked: false)
      end
    end

    context 'when build is parallelized' do
      shared_examples 'parallelized jobs config' do
        let(:index) { 3 }
        let(:total) { 5 }

        before do
          build.options[:parallel] = config
          build.options[:instance] = index
        end

        it 'includes CI_NODE_INDEX' do
          is_expected.to include(
            { key: 'CI_NODE_INDEX', value: index.to_s, public: true, masked: false }
          )
        end

        it 'includes correct CI_NODE_TOTAL' do
          is_expected.to include(
            { key: 'CI_NODE_TOTAL', value: total.to_s, public: true, masked: false }
          )
        end
      end

      context 'when parallel is a number' do
        let(:config) { 5 }

        it_behaves_like 'parallelized jobs config'
      end

      context 'when parallel is hash with the total key' do
        let(:config) { { total: 5 } }

        it_behaves_like 'parallelized jobs config'
      end

      context 'when parallel is nil' do
        let(:config) {}

        it_behaves_like 'parallelized jobs config' do
          let(:total) { 1 }
        end
      end
    end

    context 'when build has not been persisted yet' do
      let(:build) do
        FactoryBot.build(:ci_build,
          name: 'rspec',
          ci_stage: pipeline.stages.first,
          ref: 'feature',
          project: project,
          pipeline: pipeline
        )
      end

      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'feature') }

      context 'and id_tokens are not present in the build' do
        it 'does not return id_token variables' do
          expect(build.variables)
            .not_to include(key: 'ID_TOKEN_1', value: 'feature', public: true, masked: false)
        end
      end

      context 'and id_tokens are present in the build' do
        before do
          build.id_tokens = {
            'ID_TOKEN_1' => { aud: 'developers' },
            'ID_TOKEN_2' => { aud: 'maintainers' }
          }
        end

        it 'returns static predefined variables' do
          expect(build.variables)
            .to include(key: 'CI_COMMIT_REF_NAME', value: 'feature', public: true, masked: false)
          expect(build).not_to be_persisted
        end
      end
    end

    context 'for deploy tokens' do
      let(:deploy_token) { create(:deploy_token, :gitlab_deploy_token) }

      let(:deploy_token_variables) do
        [
          { key: 'CI_DEPLOY_USER', value: deploy_token.username, public: true, masked: false },
          { key: 'CI_DEPLOY_PASSWORD', value: deploy_token.token, public: false, masked: true }
        ]
      end

      context 'when gitlab-deploy-token exists for project' do
        before do
          project.deploy_tokens << deploy_token
        end

        it 'includes deploy token variables' do
          is_expected.to include(*deploy_token_variables)
        end
      end

      context 'when gitlab-deploy-token does not exist for project' do
        it 'does not include deploy token variables' do
          expect(subject.find { |v| v[:key] == 'CI_DEPLOY_USER' }).to be_nil
          expect(subject.find { |v| v[:key] == 'CI_DEPLOY_PASSWORD' }).to be_nil
        end

        context 'when gitlab-deploy-token exists for group' do
          before do
            group.deploy_tokens << deploy_token
          end

          it 'includes deploy token variables' do
            is_expected.to include(*deploy_token_variables)
          end
        end
      end
    end

    context 'for harbor integration' do
      let(:harbor_integration) { create(:harbor_integration) }

      let(:harbor_variables) do
        [
          { key: 'HARBOR_URL', value: harbor_integration.url, public: true, masked: false },
          { key: 'HARBOR_PROJECT', value: harbor_integration.project_name, public: true, masked: false },
          { key: 'HARBOR_USERNAME', value: harbor_integration.username, public: true, masked: false },
          { key: 'HARBOR_PASSWORD', value: harbor_integration.password, public: false, masked: true }
        ]
      end

      context 'when harbor_integration exists' do
        before do
          build.project.update!(harbor_integration: harbor_integration)
        end

        it 'includes harbor variables' do
          is_expected.to include(*harbor_variables)
        end
      end

      context 'when harbor_integration does not exist' do
        it 'does not include harbor variables' do
          expect(subject.find { |v| v[:key] == 'HARBOR_URL' }).to be_nil
          expect(subject.find { |v| v[:key] == 'HARBOR_PROJECT_NAME' }).to be_nil
          expect(subject.find { |v| v[:key] == 'HARBOR_USERNAME' }).to be_nil
          expect(subject.find { |v| v[:key] == 'HARBOR_PASSWORD' }).to be_nil
        end
      end
    end

    context 'for the apple_app_store integration' do
      before do
        allow(build.pipeline).to receive(:protected_ref?).and_return(pipeline_protected_ref)
      end

      let(:apple_app_store_variables) do
        [
          { key: 'APP_STORE_CONNECT_API_KEY_ISSUER_ID', value: apple_app_store_integration.app_store_issuer_id, masked: true, public: false },
          { key: 'APP_STORE_CONNECT_API_KEY_KEY', value: Base64.encode64(apple_app_store_integration.app_store_private_key), masked: true, public: false },
          { key: 'APP_STORE_CONNECT_API_KEY_KEY_ID', value: apple_app_store_integration.app_store_key_id, masked: true, public: false },
          { key: 'APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64', value: "true", masked: false, public: false }
        ]
      end

      shared_examples 'does not include the apple_app_store variables' do
        specify do
          expect(subject.find { |v| v[:key] == 'APP_STORE_CONNECT_API_KEY_ISSUER_ID' }).to be_nil
          expect(subject.find { |v| v[:key] == 'APP_STORE_CONNECT_API_KEY_KEY' }).to be_nil
          expect(subject.find { |v| v[:key] == 'APP_STORE_CONNECT_API_KEY_KEY_ID' }).to be_nil
          expect(subject.find { |v| v[:key] == 'APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64' }).to be_nil
        end
      end

      shared_examples 'includes apple_app_store variables' do
        specify do
          expect(subject).to include(*apple_app_store_variables)
        end
      end

      context 'when an Apple App Store integration exists' do
        let_it_be(:apple_app_store_integration) do
          create(:apple_app_store_integration, project: project)
        end

        context 'when app_store_protected_refs is true' do
          context 'when a build is protected' do
            let(:pipeline_protected_ref) { true }

            include_examples 'includes apple_app_store variables'
          end

          context 'when a build is not protected' do
            let(:pipeline_protected_ref) { false }

            include_examples 'does not include the apple_app_store variables'
          end
        end

        context 'when app_store_protected_refs is false' do
          before do
            apple_app_store_integration.update!(app_store_protected_refs: false)
          end

          context 'when a build is protected' do
            let(:pipeline_protected_ref) { true }

            include_examples 'includes apple_app_store variables'
          end

          context 'when a build is not protected' do
            let(:pipeline_protected_ref) { false }

            include_examples 'includes apple_app_store variables'
          end
        end
      end

      context 'when an Apple App Store integration does not exist' do
        context 'when a build is protected' do
          let(:pipeline_protected_ref) { true }

          include_examples 'does not include the apple_app_store variables'
        end

        context 'when a build is not protected' do
          let(:pipeline_protected_ref) { false }

          include_examples 'does not include the apple_app_store variables'
        end
      end
    end

    context 'for the diffblue_cover integration' do
      context 'when active' do
        let_it_be(:diffblue_cover_integration) { create(:diffblue_cover_integration, active: true) }

        let(:diffblue_cover_variables) do
          [
            { key: 'DIFFBLUE_LICENSE_KEY', value: diffblue_cover_integration.diffblue_license_key, masked: true, public: false },
            { key: 'DIFFBLUE_ACCESS_TOKEN_NAME', value: diffblue_cover_integration.diffblue_access_token_name, masked: true, public: false },
            { key: 'DIFFBLUE_ACCESS_TOKEN', value: diffblue_cover_integration.diffblue_access_token_secret, masked: true, public: false }
          ]
        end

        it 'includes diffblue_cover variables' do
          is_expected.to include(*diffblue_cover_variables)
        end
      end

      context 'when inactive' do
        let_it_be(:diffblue_cover_integration) { create(:diffblue_cover_integration, active: false) }

        it 'does not include diffblue_cover variables' do
          expect(subject.find { |v| v[:key] == 'DIFFBLUE_LICENSE_KEY' }).to be_nil
          expect(subject.find { |v| v[:key] == 'DIFFBLUE_ACCESS_TOKEN_NAME' }).to be_nil
          expect(subject.find { |v| v[:key] == 'DIFFBLUE_ACCESS_TOKEN' }).to be_nil
        end
      end
    end

    context 'for the google_play integration' do
      before do
        allow(build.pipeline).to receive(:protected_ref?).and_return(pipeline_protected_ref)
      end

      let(:google_play_variables) do
        [
          { key: "SUPPLY_JSON_KEY_DATA", value: google_play_integration.service_account_key, masked: true, public: false },
          { key: "SUPPLY_PACKAGE_NAME", value: google_play_integration.package_name, masked: false, public: false }
        ]
      end

      shared_examples 'does not include the google_play_variables' do
        specify do
          expect(subject.find { |v| v[:key] == "SUPPLY_JSON_KEY_DATA" }).to be_nil
          expect(subject.find { |v| v[:key] == "SUPPLY_PACKAGE_NAME" }).to be_nil
        end
      end

      shared_examples 'includes google_play_variables' do
        specify do
          expect(subject).to include(*google_play_variables)
        end
      end

      context 'when the google_play integration exists' do
        let_it_be(:google_play_integration) do
          create(:google_play_integration, project: project)
        end

        context 'when google_play_protected_refs is true' do
          context 'when a build is protected' do
            let(:pipeline_protected_ref) { true }

            include_examples 'includes google_play_variables'
          end

          context 'when a build is not protected' do
            let(:pipeline_protected_ref) { false }

            include_examples 'does not include the google_play_variables'
          end
        end

        context 'when google_play_protected_refs is false' do
          before do
            google_play_integration.update!(google_play_protected_refs: false)
          end

          context 'when a build is protected' do
            let(:pipeline_protected_ref) { true }

            include_examples 'includes google_play_variables'
          end

          context 'when a build is not protected' do
            let(:pipeline_protected_ref) { false }

            include_examples 'includes google_play_variables'
          end
        end
      end

      context 'when the google_play integration does not exist' do
        context 'when a build is protected' do
          let(:pipeline_protected_ref) { true }

          include_examples 'does not include the google_play_variables'
        end

        context 'when a build is not protected' do
          let(:pipeline_protected_ref) { false }

          include_examples 'does not include the google_play_variables'
        end
      end
    end

    context 'when build has dependency which has dotenv variable in same project' do
      let!(:prepare) { create(:ci_build, pipeline: pipeline, stage_idx: 0) }
      let!(:build) { create(:ci_build, pipeline: pipeline, stage_idx: 1, options: { dependencies: [prepare.name] }) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare, accessibility: accessibility) }

      let!(:job_variable) { create(:ci_job_variable, :dotenv_source, job: prepare) }

      context "when artifact is public" do
        let(:accessibility) { 'public' }

        it { is_expected.to include(key: job_variable.key, value: job_variable.value, public: false, masked: false) }
      end

      context "when artifact is private" do
        let(:accessibility) { 'private' }

        it { is_expected.to include(key: job_variable.key, value: job_variable.value, public: false, masked: false) }
      end
    end

    context 'when build has dependency which has dotenv variable in different project' do
      let!(:prepare) { create(:ci_build, pipeline: pipeline, stage_idx: 0) }
      let!(:build) { create(:ci_build, project: public_project, stage_idx: 1, options: { dependencies: [prepare.name] }) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare, accessibility: accessibility) }

      let!(:job_variable) { create(:ci_job_variable, :dotenv_source, job: prepare) }

      context "when artifact is public" do
        let(:accessibility) { 'public' }

        it { is_expected.to include(key: job_variable.key, value: job_variable.value, public: false, masked: false) }
      end

      context "when artifact is private" do
        let(:accessibility) { 'private' }

        it { is_expected.not_to include(key: job_variable.key, value: job_variable.value, public: false, masked: false) }
      end
    end

    context 'when ID tokens are defined on the build' do
      before do
        rsa_key = OpenSSL::PKey::RSA.generate(3072).to_s
        stub_application_setting(ci_jwt_signing_key: rsa_key)
        build.metadata.update!(id_tokens: {
                                 'ID_TOKEN_1' => { aud: 'developers' },
                                 'ID_TOKEN_2' => { aud: 'maintainers' }
                               })
        build.runner = build_stubbed(:ci_runner)
      end

      subject(:runner_vars) { build.variables.to_runner_variables }

      it 'includes the ID token variables' do
        expect(runner_vars).to include(
          a_hash_including(key: 'ID_TOKEN_1', public: false, masked: true),
          a_hash_including(key: 'ID_TOKEN_2', public: false, masked: true)
        )

        id_token_var_1 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_1' }
        id_token_var_2 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_2' }
        id_token_1 = JWT.decode(id_token_var_1[:value], nil, false).first
        id_token_2 = JWT.decode(id_token_var_2[:value], nil, false).first
        expect(id_token_1['aud']).to eq('developers')
        expect(id_token_2['aud']).to eq('maintainers')
      end

      context 'when a NoSigningKeyError is raised' do
        it 'does not include the ID token variables' do
          allow(::Gitlab::Ci::JwtV2).to receive(:for_build).and_raise(::Gitlab::Ci::Jwt::NoSigningKeyError)

          expect(runner_vars.map { |var| var[:key] }).not_to include('ID_TOKEN_1', 'ID_TOKEN_2')
        end
      end

      context 'when a RSAError is raised' do
        it 'does not include the ID token variables' do
          allow(::Gitlab::Ci::JwtV2).to receive(:for_build).and_raise(::OpenSSL::PKey::RSAError)

          expect(runner_vars.map { |var| var[:key] }).not_to include('ID_TOKEN_1', 'ID_TOKEN_2')
        end
      end
    end

    context 'when ID tokens are defined with variables' do
      let(:ci_server_url) { Gitlab.config.gitlab.url }

      let(:ci_server_host) { Gitlab.config.gitlab.host }

      before do
        rsa_key = OpenSSL::PKey::RSA.generate(3072).to_s
        stub_application_setting(ci_jwt_signing_key: rsa_key)
        build.metadata.update!(id_tokens: {
                                 'ID_TOKEN_1' => { aud: '$CI_SERVER_URL' },
                                 'ID_TOKEN_2' => { aud: 'https://$CI_SERVER_HOST' },
                                 'ID_TOKEN_3' => { aud: ['developers', '$CI_SERVER_URL', 'https://$CI_SERVER_HOST'] }
                               })
        build.runner = build_stubbed(:ci_runner)
      end

      subject(:runner_vars) { build.variables.to_runner_variables }

      it 'includes the ID token variables with expanded aud values' do
        expect(runner_vars).to include(
          a_hash_including(key: 'ID_TOKEN_1', public: false, masked: true),
          a_hash_including(key: 'ID_TOKEN_2', public: false, masked: true),
          a_hash_including(key: 'ID_TOKEN_3', public: false, masked: true)
        )

        id_token_var_1 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_1' }
        id_token_var_2 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_2' }
        id_token_var_3 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_3' }
        id_token_1 = JWT.decode(id_token_var_1[:value], nil, false).first
        id_token_2 = JWT.decode(id_token_var_2[:value], nil, false).first
        id_token_3 = JWT.decode(id_token_var_3[:value], nil, false).first
        expect(id_token_1['aud']).to eq(ci_server_url)
        expect(id_token_2['aud']).to eq("https://#{ci_server_host}")
        expect(id_token_3['aud']).to match_array(['developers', ci_server_url, "https://#{ci_server_host}"])
      end
    end

    context 'when ID tokens are defined with variables of an environment' do
      let!(:envprod) do
        create(:environment, project: build.project, name: 'production')
      end

      let!(:varprod) do
        create(:ci_variable, project: build.project, key: 'ENVIRONMENT_SCOPED_VAR', value: 'https://prod', environment_scope: 'prod*')
      end

      before do
        build.update!(environment: 'production')
        rsa_key = OpenSSL::PKey::RSA.generate(3072).to_s
        stub_application_setting(ci_jwt_signing_key: rsa_key)
        build.metadata.update!(id_tokens: {
                                 'ID_TOKEN_1' => { aud: '$ENVIRONMENT_SCOPED_VAR' },
                                 'ID_TOKEN_2' => { aud: ['$CI_ENVIRONMENT_NAME', '$ENVIRONMENT_SCOPED_VAR'] }
                               })
        build.runner = build_stubbed(:ci_runner)
      end

      subject(:runner_vars) { build.variables.to_runner_variables }

      it 'includes the ID token variables with expanded aud values' do
        expect(runner_vars).to include(
          a_hash_including(key: 'ID_TOKEN_1', public: false, masked: true),
          a_hash_including(key: 'ID_TOKEN_2', public: false, masked: true)
        )

        id_token_var_1 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_1' }
        id_token_var_2 = runner_vars.find { |var| var[:key] == 'ID_TOKEN_2' }
        id_token_1 = JWT.decode(id_token_var_1[:value], nil, false).first
        id_token_2 = JWT.decode(id_token_var_2[:value], nil, false).first
        expect(id_token_1['aud']).to eq('https://prod')
        expect(id_token_2['aud']).to match_array(['production', 'https://prod'])
      end
    end
  end

  describe '#scoped_variables' do
    it 'records a prometheus metric' do
      histogram = double(:histogram)
      expect(::Gitlab::Ci::Pipeline::Metrics).to receive(:pipeline_builder_scoped_variables_histogram)
        .and_return(histogram)

      expect(histogram).to receive(:observe)
        .with({}, a_kind_of(ActiveSupport::Duration))

      build.scoped_variables
    end

    shared_examples 'calculates scoped_variables' do
      context 'when build has not been persisted yet' do
        let(:ci_stage) { create(:ci_stage) }
        let(:build) do
          FactoryBot.build(
            :ci_build,
            name: 'rspec',
            ci_stage: ci_stage,
            ref: 'feature',
            project: project,
            pipeline: pipeline,
            scheduling_type: :stage
          )
        end

        let(:pipeline) { create(:ci_pipeline, project: project, ref: 'feature') }

        it 'does not persist the build' do
          expect(build).to be_valid
          expect(build).not_to be_persisted

          build.scoped_variables

          expect(build).not_to be_persisted
        end

        it 'returns static predefined variables' do
          keys = %w[CI_JOB_NAME
                    CI_COMMIT_SHA
                    CI_COMMIT_SHORT_SHA
                    CI_COMMIT_REF_NAME
                    CI_COMMIT_REF_SLUG
                    CI_JOB_STAGE]

          variables = build.scoped_variables

          variables.map { |env| env[:key] }.tap do |names|
            expect(names).to include(*keys)
          end

          expect(variables)
            .to include(key: 'CI_COMMIT_REF_NAME', value: 'feature', public: true, masked: false)
        end

        it 'does not return prohibited variables' do
          keys = %w[CI_JOB_ID
                    CI_JOB_URL
                    CI_JOB_TOKEN
                    CI_REGISTRY_USER
                    CI_REGISTRY_PASSWORD
                    CI_REPOSITORY_URL
                    CI_ENVIRONMENT_URL
                    CI_DEPLOY_USER
                    CI_DEPLOY_PASSWORD]

          build.scoped_variables.map { |env| env[:key] }.tap do |names|
            expect(names).not_to include(*keys)
          end
        end
      end

      context 'with dependency variables in the same project' do
        let!(:prepare) { create(:ci_build, name: 'prepare', pipeline: pipeline, stage_idx: 0) }
        let!(:build) { create(:ci_build, pipeline: pipeline, stage_idx: 1, options: { dependencies: ['prepare'] }) }
        let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare, accessibility: accessibility_config) }

        let!(:job_variable) { create(:ci_job_variable, :dotenv_source, job: prepare) }

        context 'inherits dependent variables that are public' do
          let(:accessibility_config) { 'public' }

          it { expect(build.scoped_variables.to_hash).to include(job_variable.key => job_variable.value) }
        end

        context 'inherits dependent variables that are private' do
          let(:accessibility_config) { 'private' }

          it { expect(build.scoped_variables.to_hash).to include(job_variable.key => job_variable.value) }
        end
      end

      context 'with dependency variables in different project' do
        let!(:prepare) { create(:ci_build, name: 'prepare', pipeline: pipeline, stage_idx: 0) }
        let!(:build) { create(:ci_build, project: public_project, stage_idx: 1, options: { dependencies: ['prepare'] }) }
        let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare, accessibility: accessibility_config) }

        let!(:job_variable) { create(:ci_job_variable, :dotenv_source, job: prepare) }

        context 'inherits dependent variables that are public' do
          let(:accessibility_config) { 'public' }

          it { expect(build.scoped_variables.to_hash).to include(job_variable.key => job_variable.value) }
        end

        context 'does not inherit dependent variables that are private' do
          let(:accessibility_config) { 'private' }

          it { expect(build.scoped_variables.to_hash).not_to include(job_variable.key => job_variable.value) }
        end
      end
    end

    it_behaves_like 'calculates scoped_variables'

    it 'delegates to the variable builders' do
      expect_next_instance_of(Gitlab::Ci::Variables::Builder) do |builder|
        expect(builder)
          .to receive(:scoped_variables).with(build, hash_including(:environment, :dependencies))
          .and_call_original

        expect(builder).to receive(:predefined_variables).and_call_original
      end

      build.scoped_variables
    end
  end

  describe '#simple_variables_without_dependencies' do
    it 'does not load dependencies' do
      expect(build).not_to receive(:dependency_variables)

      build.simple_variables_without_dependencies
    end
  end

  describe '#any_unmet_prerequisites?' do
    let(:build) { create(:ci_build, :created, pipeline: pipeline) }

    subject { build.any_unmet_prerequisites? }

    before do
      allow(build).to receive(:prerequisites).and_return(prerequisites)
    end

    context 'build has prerequisites' do
      let(:prerequisites) { [double] }

      it { is_expected.to be_truthy }
    end

    context 'build does not have prerequisites' do
      let(:prerequisites) { [] }

      it { is_expected.to be_falsey }
    end
  end

  describe '#yaml_variables' do
    let(:build) { create(:ci_build, pipeline: pipeline, yaml_variables: variables) }

    let(:variables) do
      [
        { 'key' => :VARIABLE, 'value' => 'my value' },
        { 'key' => 'VARIABLE2', 'value' => 'my value 2' }
      ]
    end

    shared_examples 'having consistent representation' do
      it 'allows to access using symbols' do
        expect(build.reload.yaml_variables.first[:key]).to eq('VARIABLE')
        expect(build.reload.yaml_variables.first[:value]).to eq('my value')
        expect(build.reload.yaml_variables.second[:key]).to eq('VARIABLE2')
        expect(build.reload.yaml_variables.second[:value]).to eq('my value 2')
      end
    end

    it_behaves_like 'having consistent representation'

    it 'persist data in build metadata' do
      expect(build.metadata.read_attribute(:config_variables)).not_to be_nil
    end

    it 'does not persist data in build' do
      expect(build.read_attribute(:yaml_variables)).to be_nil
    end
  end

  describe '#dependency_variables' do
    subject { build.dependency_variables }

    context 'when using dependencies in the same project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare2) { create(:ci_build, name: 'prepare2', pipeline: pipeline, stage_idx: 0) }
      let!(:build) { create(:ci_build, pipeline: pipeline, stage_idx: 1, options: { dependencies: ['prepare1'] }) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, job: prepare1) }
      let!(:job_variable_3) { create(:ci_job_variable, :dotenv_source, job: prepare2) }

      context 'inherits only dependent variables that are public' do
        let(:accessibility) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'inherits dependent variables that are private' do
        let(:accessibility) { 'private' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end
    end

    context 'when using dependencies in a different project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare2) { create(:ci_build, name: 'prepare2', pipeline: pipeline, stage_idx: 0) }
      let!(:build) { create(:ci_build, project: public_project, stage_idx: 1, options: { dependencies: ['prepare1'] }) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, job: prepare1) }
      let!(:job_variable_3) { create(:ci_job_variable, :dotenv_source, job: prepare2) }

      context 'inherits only dependent variables that are public' do
        let(:accessibility) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'does not inherit dependent variables that are private' do
        let(:accessibility) { 'private' }

        it { expect(subject.to_hash).not_to eq(job_variable_1.key => job_variable_1.value) }
      end
    end

    context 'when using needs in the same project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare2) { create(:ci_build, name: 'prepare2', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare3) { create(:ci_build, name: 'prepare3', pipeline: pipeline, stage_idx: 0) }
      let!(:build) { create(:ci_build, pipeline: pipeline, stage_idx: 1, scheduling_type: 'dag') }
      let!(:build_needs_prepare1) { create(:ci_build_need, build: build, name: 'prepare1', artifacts: true) }
      let!(:build_needs_prepare2) { create(:ci_build_need, build: build, name: 'prepare2', artifacts: false) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility_config) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, :dotenv_source, job: prepare2) }
      let!(:job_variable_3) { create(:ci_job_variable, :dotenv_source, job: prepare3) }

      context 'inherits only needs with artifacts variables that are public' do
        let(:accessibility_config) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'inherits needs with artifacts variables that are private' do
        let(:accessibility_config) { 'private' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end
    end

    context 'when using needs in a different project' do
      let!(:prepare1) { create(:ci_build, name: 'prepare1', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare2) { create(:ci_build, name: 'prepare2', pipeline: pipeline, stage_idx: 0) }
      let!(:prepare3) { create(:ci_build, name: 'prepare3', pipeline: pipeline, stage_idx: 0) }
      let!(:build) { create(:ci_build, project: public_project, stage_idx: 1, scheduling_type: 'dag') }
      let!(:build_needs_prepare1) { create(:ci_build_need, build: build, name: 'prepare1', artifacts: true) }
      let!(:build_needs_prepare2) { create(:ci_build_need, build: build, name: 'prepare2', artifacts: false) }
      let!(:job_artifact) { create(:ci_job_artifact, :dotenv, job: prepare1, accessibility: accessibility_config) }

      let!(:job_variable_1) { create(:ci_job_variable, :dotenv_source, job: prepare1) }
      let!(:job_variable_2) { create(:ci_job_variable, :dotenv_source, job: prepare2) }
      let!(:job_variable_3) { create(:ci_job_variable, :dotenv_source, job: prepare3) }

      context 'inherits only needs with artifacts variables that are public' do
        let(:accessibility_config) { 'public' }

        it { expect(subject.to_hash).to eq(job_variable_1.key => job_variable_1.value) }
      end

      context 'does not inherit needs with artifacts variables that are private' do
        let(:accessibility_config) { 'private' }

        it { expect(subject.to_hash).not_to eq(job_variable_1.key => job_variable_1.value) }
      end
    end
  end

  describe 'state transition: any => [:preparing]' do
    let(:build) { create(:ci_build, :created, pipeline: pipeline) }

    before do
      allow(build).to receive(:prerequisites).and_return([double])
    end

    it 'queues BuildPrepareWorker' do
      expect(Ci::BuildPrepareWorker).to receive(:perform_async).with(build.id)

      build.enqueue
    end
  end

  describe 'state transition: any => [:pending]' do
    let(:build) { create(:ci_build, :created, pipeline: pipeline) }

    it 'queues BuildQueueWorker' do
      expect(BuildQueueWorker).to receive(:perform_async).with(build.id)

      build.enqueue
    end

    it 'executes hooks' do
      expect(build).to receive(:execute_hooks)

      build.enqueue
    end

    context 'with a database token' do
      before do
        stub_feature_flags(ci_job_token_jwt: false)
      end

      it 'assigns the token' do
        expect { build.enqueue }.to change(build, :token).from(nil).to(an_instance_of(String))
      end
    end
  end

  describe 'state transition: pending: :running' do
    let_it_be_with_reload(:runner) { create(:ci_runner) }
    let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }

    let(:job) { create(:ci_build, :pending, runner: runner, pipeline: pipeline) }

    before do
      job.project.update_attribute(:build_timeout, 1800)
    end

    def run_job_without_exception
      job.run!
    rescue StateMachines::InvalidTransition
    end

    context 'for pipeline ref existence' do
      it 'ensures pipeline ref creation' do
        expect(job.pipeline).to receive(:ensure_persistent_ref).once.and_call_original
        expect(job.pipeline.persistent_ref).to receive(:create).once

        run_job_without_exception
      end

      it 'ensures that it is not run in database transaction' do
        expect(job.pipeline.persistent_ref).to receive(:create) do
          expect(ApplicationRecord).not_to be_inside_transaction
        end

        run_job_without_exception
      end
    end

    shared_examples 'saves data on transition' do
      it 'saves timeout' do
        expect { job.run! }.to change { job.reload.ensure_metadata.timeout }.from(nil).to(expected_timeout)
      end

      it 'saves timeout_source' do
        expect { job.run! }.to change { job.reload.ensure_metadata.timeout_source }.from('unknown_timeout_source').to(expected_timeout_source)
      end

      context 'when Ci::BuildMetadata#update_timeout_state fails update' do
        before do
          allow_any_instance_of(Ci::BuildMetadata).to receive(:update_timeout_state).and_return(false)
        end

        it "doesn't save timeout" do
          expect { run_job_without_exception }.not_to change { job.reload.ensure_metadata.timeout }
        end

        it "doesn't save timeout_source" do
          expect { run_job_without_exception }.not_to change { job.reload.ensure_metadata.timeout_source }
        end
      end
    end

    context 'when runner timeout overrides project timeout' do
      let(:expected_timeout) { 900 }
      let(:expected_timeout_source) { 'runner_timeout_source' }

      before do
        runner.update_attribute(:maximum_timeout, 900)
      end

      it_behaves_like 'saves data on transition'
    end

    context "when runner timeout doesn't override project timeout" do
      let(:expected_timeout) { 1800 }
      let(:expected_timeout_source) { 'project_timeout_source' }

      before do
        runner.update_attribute(:maximum_timeout, 3600)
      end

      it_behaves_like 'saves data on transition'
    end
  end

  describe '#has_valid_build_dependencies?' do
    shared_examples 'validation is active' do
      context 'when depended job has not been completed yet' do
        let!(:pre_stage_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect(job).to have_valid_build_dependencies }
      end

      context 'when artifacts of depended job has been expired' do
        let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

        context 'when pipeline is not locked' do
          before do
            build.pipeline.unlocked!
          end

          it { expect(job).not_to have_valid_build_dependencies }
        end

        context 'when pipeline is locked' do
          before do
            build.pipeline.artifacts_locked!
          end

          it { expect(job).to have_valid_build_dependencies }
        end
      end

      context 'when artifacts of depended job has been erased' do
        let!(:pre_stage_job) do
          create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago)
        end

        it { expect(job).not_to have_valid_build_dependencies }
      end
    end

    shared_examples 'validation is not active' do
      context 'when depended job has not been completed yet' do
        let!(:pre_stage_job) { create(:ci_build, :manual, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect(job).to have_valid_build_dependencies }
      end

      context 'when artifacts of depended job has been expired' do
        let!(:pre_stage_job) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test', stage_idx: 0) }

        it { expect(job).to have_valid_build_dependencies }
      end

      context 'when artifacts of depended job has been erased' do
        let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago) }

        it { expect(job).to have_valid_build_dependencies }
      end
    end

    let!(:job) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 1, options: options) }
    let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0) }

    context 'when "dependencies" keyword is not defined' do
      let(:options) { {} }

      it { expect(job).to have_valid_build_dependencies }
    end

    context 'when "dependencies" keyword is empty' do
      let(:options) { { dependencies: [] } }

      it { expect(job).to have_valid_build_dependencies }
    end

    context 'when "dependencies" keyword is specified' do
      let(:options) { { dependencies: ['test'] } }

      it_behaves_like 'validation is active'
    end
  end

  describe 'state transition when build fails' do
    let(:service) { ::MergeRequests::AddTodoWhenBuildFailsService.new(project: project, current_user: user) }

    before do
      allow(::MergeRequests::AddTodoWhenBuildFailsService).to receive(:new).and_return(service)
      allow(service).to receive(:close)
    end

    context 'when build is configured to be retried' do
      subject { create(:ci_build, :running, options: { script: ["ls -al"], retry: 3 }, pipeline: pipeline, user: user) }

      it 'retries build and assigns the same user to it' do
        expect_next_instance_of(::Ci::RetryJobService) do |service|
          expect(service).to receive(:execute).with(subject)
        end

        subject.drop!
      end

      it 'does not try to create a todo' do
        project.add_developer(user)

        expect(service).not_to receive(:pipeline_merge_requests)

        subject.drop!
      end

      context 'when retry service raises Gitlab::Access::AccessDeniedError exception' do
        let(:retry_service) { Ci::RetryJobService.new(subject.project, subject.user) }

        before do
          allow_any_instance_of(Ci::RetryJobService)
            .to receive(:execute)
            .with(subject)
            .and_raise(Gitlab::Access::AccessDeniedError)
          allow(Gitlab::AppLogger).to receive(:error)
        end

        it 'handles raised exception' do
          expect { subject.drop! }.not_to raise_error
        end

        it 'logs the error' do
          subject.drop!

          expect(Gitlab::AppLogger)
            .to have_received(:error)
            .with(a_string_matching("Unable to auto-retry job #{subject.id}"))
        end

        it 'fails the job' do
          subject.drop!
          expect(subject.failed?).to be_truthy
        end
      end
    end

    context 'when build is not configured to be retried' do
      subject { create(:ci_build, :running, pipeline: pipeline, user: user) }

      let(:pipeline) do
        create(:ci_pipeline,
          project: project,
          ref: 'feature',
          sha: merge_request.diff_head_sha,
          merge_requests_as_head_pipeline: [merge_request])
      end

      let(:merge_request) do
        create(:merge_request, :opened,
          source_branch: 'feature',
          source_project: project,
          target_branch: 'master',
          target_project: project)
      end

      it 'does not retry build' do
        expect(described_class).not_to receive(:retry)

        subject.drop!
      end

      it 'does not count retries when not necessary' do
        expect(described_class).not_to receive(:retry)
        expect_any_instance_of(described_class)
          .not_to receive(:retries_count)

        subject.drop!
      end

      it 'creates a todo async', :sidekiq_inline do
        project.add_developer(user)

        expect_next_instance_of(TodoService) do |todo_service|
          expect(todo_service)
            .to receive(:merge_request_build_failed).with(merge_request)
        end

        subject.drop!
      end
    end

    context 'when associated deployment failed to update its status' do
      let(:build) { create(:ci_build, :running, pipeline: pipeline) }
      let!(:deployment) { create(:deployment, deployable: build) }

      before do
        allow_any_instance_of(Deployment)
          .to receive(:drop!).and_raise('Unexpected error')
      end

      it 'can drop the build' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { build.drop! }.not_to raise_error

        expect(build).to be_failed
      end
    end
  end

  describe '#pages_generator?', feature_category: :pages do
    where(:name, :pages_config, :enabled, :result) do
      'foo' | nil | false | false
      'pages' | nil | false | false
      'pages:preview' | nil | true | false
      'pages' | nil | true | true
      'foo' | true | true | true
      'foo' | { expire_in: '1 day' } | true | true
      'foo' | false | true | false
      'pages' | false | true | false
    end

    with_them do
      before do
        stub_pages_setting(enabled: enabled)
        build.update!(name: name, options: { pages: pages_config })
        stub_feature_flags(customizable_pages_job_name: true)
      end

      subject { build.pages_generator? }

      it { is_expected.to eq(result) }
    end
  end

  describe '#pages', feature_category: :pages do
    where(:pages_generator, :options, :result) do
      false | {}                    | {}
      false | { publish: 'public' } | {}
      true  | nil                   | {}
      true  | { publish: '' }       | {}
      true  | {}                    | {}
      true  | { publish: nil }      | {}
      true  | { publish: 'public' } | { publish: 'public' }
      true  | { pages: { publish: 'public' } } | { publish: 'public' }
      true  | { publish: '$CUSTOM_FOLDER' } | { publish: 'custom_folder' }
      true  | { pages: { publish: '$CUSTOM_FOLDER' } } | { publish: 'custom_folder' }
      true  | { publish: '$CUSTOM_FOLDER/$CUSTOM_SUBFOLDER' } | { publish: 'custom_folder/custom_subfolder' }
      true  | { pages: { publish: '$CUSTOM_FOLDER/$CUSTOM_SUBFOLDER' } } | { publish: 'custom_folder/custom_subfolder' }
    end

    with_them do
      before do
        allow(build).to receive_messages(options: options)
        allow(build).to receive(:pages_generator?).and_return(pages_generator)
        # Create custom variables to test that they are properly expanded in the `build.pages.publish` property
        create(:ci_job_variable, key: 'CUSTOM_FOLDER', value: 'custom_folder', job: build)
        create(:ci_job_variable, key: 'CUSTOM_SUBFOLDER', value: 'custom_subfolder', job: build)
      end

      subject { build.pages }

      it { is_expected.to include(result) }
    end
  end

  describe 'pages deployments', feature_category: :pages do
    let_it_be(:build, reload: true) { create(:ci_build, name: 'pages', pipeline: pipeline, user: user) }

    context 'when pages are enabled' do
      before do
        stub_pages_setting(enabled: true)
      end

      context 'and job succeeds' do
        let(:expected_hostname) { "#{project.namespace.path}.example.com" }
        let(:expected_url) { "http://#{expected_hostname}/#{project.path}" }

        it "includes the expected variables" do
          expect(build.variables.to_runner_variables).to include(
            { key: 'CI_PAGES_HOSTNAME', value: expected_hostname, public: true, masked: false },
            { key: 'CI_PAGES_URL', value: expected_url, public: true, masked: false }
          )
        end

        context 'and fix_pages_ci_variables FF is disabled' do
          before do
            stub_feature_flags(fix_pages_ci_variables: false)
          end

          it "includes the expected variables" do
            expect(build.variables.to_runner_variables).to include(
              { key: 'CI_PAGES_URL', value: Gitlab::Pages::UrlBuilder.new(project).pages_url, public: true, masked: false }
            )
          end
        end

        it "calls pages worker" do
          expect(PagesWorker).to receive(:perform_async).with(:deploy, build.id)

          build.success!
        end
      end

      context 'and job fails' do
        it "does not call pages worker" do
          expect(PagesWorker).not_to receive(:perform_async)

          build.drop!
        end
      end
    end

    context 'when pages are disabled' do
      before do
        stub_pages_setting(enabled: false)
      end

      context 'and job succeeds' do
        it "does not call pages worker" do
          expect(PagesWorker).not_to receive(:perform_async)

          build.success!
        end
      end
    end
  end

  describe '#has_terminal?' do
    let(:states) { described_class.state_machines[:status].states.keys - [:running] }

    subject { build.has_terminal? }

    it 'returns true if the build is running and it has a runner_session_url' do
      build.build_runner_session(url: 'whatever')
      build.status = :running

      expect(subject).to be_truthy
    end

    context 'returns false' do
      it 'when runner_session_url is empty' do
        build.status = :running

        expect(subject).to be_falsey
      end

      context 'unless the build is running' do
        before do
          build.build_runner_session(url: 'whatever')
        end

        it do
          states.each do |state|
            build.status = state

            is_expected.to be_falsey
          end
        end
      end
    end
  end

  describe '#collect_test_reports!' do
    subject(:test_reports) { build.collect_test_reports!(Gitlab::Ci::Reports::TestReport.new) }

    it { expect(test_reports.get_suite(build.name).total_count).to eq(0) }

    context 'when build has a test report' do
      context 'when there is a JUnit test report from rspec test suite' do
        before do
          create(:ci_job_artifact, :junit, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the test suite' do
          expect { subject }.not_to raise_error

          expect(test_reports.get_suite(build.name).total_count).to eq(4)
          expect(test_reports.get_suite(build.name).success_count).to be(2)
          expect(test_reports.get_suite(build.name).failed_count).to be(2)
        end
      end

      context 'when there is a JUnit test report from java ant test suite' do
        before do
          create(:ci_job_artifact, :junit_with_ant, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the test suite' do
          expect { subject }.not_to raise_error

          expect(test_reports.get_suite(build.name).total_count).to eq(3)
          expect(test_reports.get_suite(build.name).success_count).to be(3)
          expect(test_reports.get_suite(build.name).failed_count).to be(0)
        end
      end

      context 'when there is a corrupted JUnit test report' do
        before do
          create(:ci_job_artifact, :junit_with_corrupted_data, job: build, project: build.project)
        end

        it 'returns no test data and includes a suite_error message' do
          expect { subject }.not_to raise_error

          expect(test_reports.get_suite(build.name).total_count).to eq(0)
          expect(test_reports.get_suite(build.name).success_count).to eq(0)
          expect(test_reports.get_suite(build.name).failed_count).to eq(0)
          expect(test_reports.get_suite(build.name).suite_error).to eq('JUnit XML parsing failed: 1:1: FATAL: Document is empty')
        end
      end
    end
  end

  describe '#collect_accessibility_reports!' do
    subject { build.collect_accessibility_reports!(accessibility_report) }

    let(:accessibility_report) { Gitlab::Ci::Reports::AccessibilityReports.new }

    it { expect(accessibility_report.urls).to eq({}) }

    context 'when build has an accessibility report' do
      context 'when there is an accessibility report with errors' do
        before do
          create(:ci_job_artifact, :accessibility, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the accessibility report' do
          expect { subject }.not_to raise_error

          expect(accessibility_report.urls.keys).to match_array(['https://about.gitlab.com/'])
          expect(accessibility_report.errors_count).to eq(10)
          expect(accessibility_report.scans_count).to eq(1)
          expect(accessibility_report.passes_count).to eq(0)
        end
      end

      context 'when there is an accessibility report without errors' do
        before do
          create(:ci_job_artifact, :accessibility_without_errors, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the accessibility report' do
          expect { subject }.not_to raise_error

          expect(accessibility_report.urls.keys).to match_array(['https://pa11y.org/'])
          expect(accessibility_report.errors_count).to eq(0)
          expect(accessibility_report.scans_count).to eq(1)
          expect(accessibility_report.passes_count).to eq(1)
        end
      end

      context 'when there is an accessibility report with an invalid url' do
        before do
          create(:ci_job_artifact, :accessibility_with_invalid_url, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the accessibility report' do
          expect { subject }.not_to raise_error

          expect(accessibility_report.urls).to be_empty
          expect(accessibility_report.errors_count).to eq(0)
          expect(accessibility_report.scans_count).to eq(0)
          expect(accessibility_report.passes_count).to eq(0)
        end
      end
    end
  end

  describe '#collect_codequality_reports!' do
    subject(:codequality_report) { build.collect_codequality_reports!(Gitlab::Ci::Reports::CodequalityReports.new) }

    it { expect(codequality_report.degradations).to eq({}) }

    context 'when build has a codequality report' do
      context 'when there is a codequality report' do
        before do
          create(:ci_job_artifact, :codequality, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the codequality report' do
          expect { codequality_report }.not_to raise_error

          expect(codequality_report.degradations_count).to eq(3)
        end
      end

      context 'when there is an codequality report without errors' do
        before do
          create(:ci_job_artifact, :codequality_without_errors, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the codequality report' do
          expect { codequality_report }.not_to raise_error

          expect(codequality_report.degradations_count).to eq(0)
        end
      end
    end
  end

  describe '#collect_terraform_reports!' do
    let(:terraform_reports) { Gitlab::Ci::Reports::TerraformReports.new }

    it 'returns an empty hash' do
      expect(build.collect_terraform_reports!(terraform_reports).plans).to eq({})
    end

    context 'when build has a terraform report' do
      context 'when there is a valid tfplan.json' do
        before do
          create(:ci_job_artifact, :terraform, job: build, project: build.project)
        end

        it 'parses blobs and add the results to the terraform report' do
          expect { build.collect_terraform_reports!(terraform_reports) }.not_to raise_error

          terraform_reports.plans.each do |key, hash_value|
            expect(hash_value.keys).to match_array(%w[create delete job_id job_name job_path update])
          end

          expect(terraform_reports.plans).to match(
            a_hash_including(
              build.id.to_s => a_hash_including(
                'create' => 0,
                'update' => 1,
                'delete' => 0,
                'job_name' => build.name
              )
            )
          )
        end
      end

      context 'when there is an invalid tfplan.json' do
        before do
          create(:ci_job_artifact, :terraform_with_corrupted_data, job: build, project: build.project)
        end

        it 'adds invalid plan report' do
          expect { build.collect_terraform_reports!(terraform_reports) }.not_to raise_error

          terraform_reports.plans.each do |key, hash_value|
            expect(hash_value.keys).to match_array(%w[job_id job_name job_path tf_report_error])
          end

          expect(terraform_reports.plans).to match(
            a_hash_including(
              build.id.to_s => a_hash_including(
                'tf_report_error' => :invalid_json_format
              )
            )
          )
        end
      end
    end
  end

  describe '#each_report' do
    let(:report_types) { Ci::JobArtifact.file_types_for_report(:coverage) }

    let!(:codequality) { create(:ci_job_artifact, :codequality, job: build) }
    let!(:coverage) { create(:ci_job_artifact, :coverage_gocov_xml, job: build) }
    let!(:junit) { create(:ci_job_artifact, :junit, job: build) }

    it 'yields job artifact blob that matches the type' do
      expect { |b| build.each_report(report_types, &b) }.to yield_with_args(coverage.file_type, String, coverage)
    end

    context 'when there are valid job artifact reports' do
      let(:report_types) { Ci::JobArtifact.file_types_for_report(:test) }

      before do
        create(:ci_job_artifact_report, :validated, job_artifact: junit)
      end

      it 'yields them' do
        expect { |b| build.each_report(report_types, &b) }.to yield_with_args(junit.file_type, String, junit)
      end
    end

    context 'when there are invalid job artifact reports' do
      let(:report_types) { Ci::JobArtifact.file_types_for_report(:test) }

      before do
        create(:ci_job_artifact_report, :faulty, job_artifact: junit)
      end

      it 'skips them' do
        expect { |b| build.each_report(report_types, &b) }.not_to yield_control
      end
    end
  end

  describe '#report_artifacts' do
    subject { build.report_artifacts }

    context 'when the build has reports' do
      let!(:report) { create(:ci_job_artifact, :codequality, job: build) }

      it 'returns the artifacts with reports' do
        expect(subject).to contain_exactly(report)
      end
    end
  end

  describe '#artifacts_metadata_entry' do
    let_it_be(:build) { create(:ci_build, pipeline: pipeline) }

    let(:path) { 'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif' }

    around do |example|
      freeze_time { example.run }
    end

    before do
      allow(build).to receive(:execute_hooks)
      stub_artifacts_object_storage
    end

    subject { build.artifacts_metadata_entry(path) }

    context 'when using local storage' do
      let!(:metadata) { create(:ci_job_artifact, :metadata, job: build) }

      context 'for existing file' do
        it 'does exist' do
          is_expected.to be_exists
        end
      end

      context 'for non-existing file' do
        let(:path) { 'invalid-file' }

        it 'does not exist' do
          is_expected.not_to be_exists
        end
      end
    end

    context 'when using remote storage' do
      include HttpIOHelpers

      let!(:metadata) { create(:ci_job_artifact, :remote_store, :metadata, job: build) }
      let(:file_path) { expand_fixture_path('ci_build_artifacts_metadata.gz') }

      before do
        stub_remote_url_206(metadata.file.url, file_path)
      end

      context 'for existing file' do
        it 'does exist' do
          is_expected.to be_exists
        end
      end

      context 'for non-existing file' do
        let(:path) { 'invalid-file' }

        it 'does not exist' do
          is_expected.not_to be_exists
        end
      end
    end
  end

  describe '#publishes_artifacts_reports?' do
    let(:build) { create(:ci_build, options: options, pipeline: pipeline) }

    subject { build.publishes_artifacts_reports? }

    context 'when artifacts reports are defined' do
      let(:options) do
        { artifacts: { reports: { junit: "junit.xml" } } }
      end

      it { is_expected.to be_truthy }
    end

    context 'when artifacts reports missing defined' do
      let(:options) do
        { artifacts: { paths: ["file.txt"] } }
      end

      it { is_expected.to be_falsey }
    end

    context 'when options are missing' do
      let(:options) { nil }

      it { is_expected.to be_falsey }
    end
  end

  describe '#runner_required_feature_names' do
    let(:build) { create(:ci_build, options: options, pipeline: pipeline) }

    subject { build.runner_required_feature_names }

    context 'when artifacts reports are defined' do
      let(:options) do
        { artifacts: { reports: { junit: "junit.xml" } } }
      end

      it { is_expected.to include(:upload_multiple_artifacts) }
    end

    context 'when artifacts exclude is defined' do
      let(:options) do
        { artifacts: { exclude: %w[something] } }
      end

      it { is_expected.to include(:artifacts_exclude) }
    end
  end

  describe '#supported_runner?' do
    let_it_be_with_refind(:build) { create(:ci_build, pipeline: pipeline) }

    subject { build.supported_runner?(runner_features) }

    context 'when `upload_multiple_artifacts` feature is required by build' do
      before do
        expect(build).to receive(:runner_required_feature_names) do
          [:upload_multiple_artifacts]
        end
      end

      context 'when runner provides given feature' do
        let(:runner_features) do
          { upload_multiple_artifacts: true }
        end

        it { is_expected.to be_truthy }
      end

      context 'when runner does not provide given feature' do
        let(:runner_features) do
          {}
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when `refspecs` feature is required by build' do
      before do
        allow(build).to receive(:merge_request_ref?) { true }
      end

      context 'when runner provides given feature' do
        let(:runner_features) { { refspecs: true } }

        it { is_expected.to be_truthy }
      end

      context 'when runner does not provide given feature' do
        let(:runner_features) { {} }

        it { is_expected.to be_falsey }
      end
    end

    context 'when `multi_build_steps` feature is required by build' do
      before do
        expect(build).to receive(:runner_required_feature_names) do
          [:multi_build_steps]
        end
      end

      context 'when runner provides given feature' do
        let(:runner_features) { { multi_build_steps: true } }

        it { is_expected.to be_truthy }
      end

      context 'when runner does not provide given feature' do
        let(:runner_features) { {} }

        it { is_expected.to be_falsey }
      end
    end

    context 'when `return_exit_code` feature is required by build' do
      let(:options) { { allow_failure_criteria: { exit_codes: [1] } } }

      before do
        build.update!(options: options)
      end

      context 'when runner provides given feature' do
        let(:runner_features) { { return_exit_code: true } }

        it { is_expected.to be_truthy }
      end

      context 'when runner does not provide given feature' do
        let(:runner_features) { {} }

        it { is_expected.to be_falsey }
      end

      context 'when the runner does not provide all of the required features' do
        let(:options) do
          {
            allow_failure_criteria: { exit_codes: [1] },
            artifacts: { reports: { junit: "junit.xml" } }
          }
        end

        let(:runner_features) { { return_exit_code: true } }

        it 'requires `upload_multiple_artifacts` too' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#degenerated?' do
    context 'when build is degenerated' do
      subject { create(:ci_build, :degenerated, pipeline: pipeline) }

      it { is_expected.to be_degenerated }
    end

    context 'when build is valid' do
      subject { create(:ci_build, pipeline: pipeline) }

      it { is_expected.not_to be_degenerated }

      context 'and becomes degenerated' do
        before do
          subject.degenerate!
        end

        it { is_expected.to be_degenerated }
      end
    end
  end

  describe 'degenerate!' do
    let(:build) { create(:ci_build, pipeline: pipeline) }

    subject { build.degenerate! }

    before do
      build.ensure_metadata
      build.needs.create!(name: 'another-job')
    end

    it 'drops metadata' do
      subject

      expect(build.reload).to be_degenerated
      expect(build.metadata).to be_nil
      expect(build.needs).to be_empty
    end
  end

  describe '#archived?' do
    context 'when build is degenerated' do
      subject { create(:ci_build, :degenerated, pipeline: pipeline) }

      it { is_expected.to be_archived }
    end

    context 'for old build' do
      subject { create(:ci_build, created_at: 1.day.ago, pipeline: pipeline) }

      context 'when archive_builds_in is set' do
        before do
          stub_application_setting(archive_builds_in_seconds: 3600)
        end

        it { is_expected.to be_archived }
      end

      context 'when archive_builds_in is not set' do
        before do
          stub_application_setting(archive_builds_in_seconds: nil)
        end

        it { is_expected.not_to be_archived }
      end
    end
  end

  describe '#read_metadata_attribute' do
    let(:build) { create(:ci_build, :degenerated, pipeline: pipeline) }
    let(:build_options) { { key: "build" } }
    let(:metadata_options) { { key: "metadata" } }
    let(:default_options) { { key: "default" } }

    subject { build.send(:read_metadata_attribute, :options, :config_options, default_options) }

    context 'when build and metadata options is set' do
      before do
        build.write_attribute(:options, build_options)
        build.ensure_metadata.write_attribute(:config_options, metadata_options)
      end

      it 'prefers build options' do
        is_expected.to eq(build_options)
      end
    end

    context 'when only metadata options is set' do
      before do
        build.write_attribute(:options, nil)
        build.ensure_metadata.write_attribute(:config_options, metadata_options)
      end

      it 'returns metadata options' do
        is_expected.to eq(metadata_options)
      end
    end

    context 'when none is set' do
      it 'returns default value' do
        is_expected.to eq(default_options)
      end
    end
  end

  describe '#write_metadata_attribute' do
    let(:build) { create(:ci_build, :degenerated, pipeline: pipeline) }
    let(:options) { { key: "new options" } }
    let(:existing_options) { { key: "existing options" } }

    subject { build.send(:write_metadata_attribute, :options, :config_options, options) }

    context 'when data in build is already set' do
      before do
        build.write_attribute(:options, existing_options)
      end

      it 'does set metadata options' do
        subject

        expect(build.metadata.read_attribute(:config_options)).to eq(options)
      end

      it 'does reset build options' do
        subject

        expect(build.read_attribute(:options)).to be_nil
      end
    end
  end

  describe '#invalid_dependencies' do
    let!(:pre_stage_job_valid) { create(:ci_build, :manual, pipeline: pipeline, name: 'test1', stage_idx: 0) }
    let!(:pre_stage_job_invalid) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test2', stage_idx: 1) }
    let!(:job) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 2, options: { dependencies: %w[test1 test2] }) }

    context 'when pipeline is locked' do
      before do
        build.pipeline.unlocked!
      end

      it 'returns invalid dependencies when expired' do
        expect(job.invalid_dependencies).to eq([pre_stage_job_invalid])
      end
    end

    context 'when pipeline is not locked' do
      before do
        build.pipeline.artifacts_locked!
      end

      it 'returns no invalid dependencies when expired' do
        expect(job.invalid_dependencies).to eq([])
      end
    end
  end

  describe '#execute_hooks' do
    before do
      build.clear_memoization(:build_data)
    end

    context 'when project hooks exists' do
      let(:build_data) { double(:BuildData) }

      before do
        create(:project_hook, project: project, job_events: true)
        allow(Ci::ExecuteBuildHooksWorker).to receive(:perform_async)
      end

      it 'enqueues ExecuteBuildHooksWorker' do
        expect(::Gitlab::DataBuilder::Build)
            .to receive(:build).with(build).and_return(build_data)

        build.execute_hooks

        expect(Ci::ExecuteBuildHooksWorker)
          .to have_received(:perform_async)
          .with(project.id, build_data)
      end

      context 'with blocked users' do
        before do
          allow(build).to receive(:user) { FactoryBot.build(:user, :blocked) }
        end

        it 'does not enqueue ExecuteBuildHooksWorker' do
          build.execute_hooks

          expect(Ci::ExecuteBuildHooksWorker).not_to receive(:perform_async)
        end
      end
    end
  end

  describe '#environment_auto_stop_in' do
    subject { build.environment_auto_stop_in }

    context 'when build option has environment auto_stop_in' do
      let(:build) do
        create(:ci_build, options: { environment: { name: 'test', auto_stop_in: '1 day' } }, pipeline: pipeline)
      end

      it { is_expected.to eq('1 day') }
    end

    context 'when build option does not have environment auto_stop_in' do
      let(:build) { create(:ci_build, pipeline: pipeline) }

      it { is_expected.to be_nil }
    end
  end

  describe '#degradation_threshold' do
    subject { build.degradation_threshold }

    context 'when threshold variable is defined' do
      before do
        build.yaml_variables = [
          { key: 'SOME_VAR_1', value: 'SOME_VAL_1' },
          { key: 'DEGRADATION_THRESHOLD', value: '5' },
          { key: 'SOME_VAR_2', value: 'SOME_VAL_2' }
        ]
      end

      it { is_expected.to eq(5) }
    end

    context 'when threshold variable is not defined' do
      before do
        build.yaml_variables = [
          { key: 'SOME_VAR_1', value: 'SOME_VAL_1' },
          { key: 'SOME_VAR_2', value: 'SOME_VAL_2' }
        ]
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#run_on_status_commit' do
    it 'runs provided hook after status commit' do
      action = spy('action')

      build.run_on_status_commit { action.perform! }
      build.success!

      expect(action).to have_received(:perform!).once
    end

    it 'does not run hooks when status has not changed' do
      action = spy('action')

      build.run_on_status_commit { action.perform! }
      build.save!

      expect(action).not_to have_received(:perform!)
    end
  end

  describe '#debug_mode?' do
    subject { build.debug_mode? }

    context 'when CI_DEBUG_TRACE=true is in variables' do
      ['true', 1, 'y'].each do |value|
        it 'reflects instance variables' do
          create(:ci_instance_variable, key: 'CI_DEBUG_TRACE', value: value)

          is_expected.to eq true
        end

        it 'reflects group variables' do
          create(:ci_group_variable, key: 'CI_DEBUG_TRACE', value: value, group: project.group)

          is_expected.to eq true
        end

        it 'reflects pipeline variables' do
          create(:ci_pipeline_variable, key: 'CI_DEBUG_TRACE', value: value, pipeline: pipeline)

          is_expected.to eq true
        end

        it 'reflects project variables' do
          create(:ci_variable, key: 'CI_DEBUG_TRACE', value: value, project: project)

          is_expected.to eq true
        end

        it 'reflects job variables' do
          create(:ci_job_variable, key: 'CI_DEBUG_TRACE', value: value, job: build)

          is_expected.to eq true
        end

        it 'when in yaml variables' do
          build.update!(yaml_variables: [{ key: :CI_DEBUG_TRACE, value: value.to_s }])

          is_expected.to eq true
        end
      end
    end

    context 'when CI_DEBUG_TRACE is not in variables' do
      it { is_expected.to eq false }
    end

    context 'when CI_DEBUG_SERVICES=true is in variables' do
      ['true', 1, 'y'].each do |value|
        it 'reflects instance variables' do
          create(:ci_instance_variable, key: 'CI_DEBUG_SERVICES', value: value)

          is_expected.to eq true
        end

        it 'reflects group variables' do
          create(:ci_group_variable, key: 'CI_DEBUG_SERVICES', value: value, group: project.group)

          is_expected.to eq true
        end

        it 'reflects pipeline variables' do
          create(:ci_pipeline_variable, key: 'CI_DEBUG_SERVICES', value: value, pipeline: pipeline)

          is_expected.to eq true
        end

        it 'reflects project variables' do
          create(:ci_variable, key: 'CI_DEBUG_SERVICES', value: value, project: project)

          is_expected.to eq true
        end

        it 'reflects job variables' do
          create(:ci_job_variable, key: 'CI_DEBUG_SERVICES', value: value, job: build)

          is_expected.to eq true
        end

        it 'when in yaml variables' do
          build.update!(yaml_variables: [{ key: :CI_DEBUG_SERVICES, value: value.to_s }])

          is_expected.to eq true
        end
      end
    end

    context 'when CI_DEBUG_SERVICES is not in variables' do
      it { is_expected.to eq false }
    end

    context 'when metadata has debug_trace_enabled true' do
      before do
        build.metadata.update!(debug_trace_enabled: true)
      end

      it { is_expected.to eq true }
    end

    context 'when metadata has debug_trace_enabled false' do
      before do
        build.metadata.update!(debug_trace_enabled: false)
      end

      it { is_expected.to eq false }
    end

    context 'when metadata does not exist' do
      before do
        build.metadata.destroy!
      end

      it { is_expected.to eq false }
    end
  end

  describe '#drop_with_exit_code!' do
    let(:exit_code) { 1 }
    let(:options) { {} }

    before do
      build.options.merge!(options)
      build.save!
    end

    subject(:drop_with_exit_code) do
      build.drop_with_exit_code!(:unknown_failure, exit_code)
    end

    it 'correctly sets the exit code' do
      expect { drop_with_exit_code }
        .to change { build.reload.metadata&.exit_code }.from(nil).to(1)
    end

    shared_examples 'drops the build without changing allow_failure' do
      it 'does not change allow_failure' do
        expect { drop_with_exit_code }
          .not_to change { build.reload.allow_failure }
      end

      it 'drops the build' do
        expect { drop_with_exit_code }
          .to change { build.reload.failed? }
      end
    end

    context 'when exit_codes are not defined' do
      it_behaves_like 'drops the build without changing allow_failure'
    end

    context 'when allow_failure_criteria is nil' do
      let(:options) { { allow_failure_criteria: nil } }

      it_behaves_like 'drops the build without changing allow_failure'
    end

    context 'when exit_codes is nil' do
      let(:options) do
        {
          allow_failure_criteria: {
            exit_codes: nil
          }
        }
      end

      it_behaves_like 'drops the build without changing allow_failure'
    end

    context 'when exit_codes do not match' do
      let(:options) do
        {
          allow_failure_criteria: {
            exit_codes: [2, 3, 4]
          }
        }
      end

      it_behaves_like 'drops the build without changing allow_failure'
    end

    context 'with matching exit codes' do
      let(:options) do
        { allow_failure_criteria: { exit_codes: [1, 2, 3] } }
      end

      it 'changes allow_failure' do
        expect { drop_with_exit_code }
          .to change { build.reload.allow_failure }
      end

      it 'drops the build' do
        expect { drop_with_exit_code }
          .to change { build.reload.failed? }
      end

      context 'when exit_code is nil' do
        let(:exit_code) {}

        it_behaves_like 'drops the build without changing allow_failure'
      end
    end

    context 'when build is configured to be retried' do
      let(:options) { { retry: 3 } }

      context 'when there is an MR attached to the pipeline and a failed job todo for that MR' do
        let!(:merge_request) { create(:merge_request, source_project: project, author: user, head_pipeline: pipeline) }
        let!(:todo) { create(:todo, :build_failed, user: user, project: project, author: user, target: merge_request) }

        before do
          build.update!(user: user)
          project.add_developer(user)
        end

        it 'resolves the todo for the old failed build' do
          expect do
            drop_with_exit_code
          end.to change { todo.reload.state }.from('pending').to('done')
        end
      end
    end

    context 'when exit code is greater than 32767' do
      let(:exit_code) { 32770 }

      it 'wraps around to max size of a signed smallint' do
        expect { drop_with_exit_code }
        .to change { build.reload.metadata&.exit_code }.from(nil).to(32767)
      end
    end
  end

  describe '#exit_codes_defined?' do
    let(:options) { {} }

    before do
      build.options.merge!(options)
    end

    subject(:exit_codes_defined) do
      build.exit_codes_defined?
    end

    context 'without allow_failure_criteria nor retry' do
      it { is_expected.to be_falsey }
    end

    context 'with allow_failure_critera' do
      context 'when exit_codes is nil' do
        let(:options) do
          {
            allow_failure_criteria: {
              exit_codes: nil
            }
          }
        end

        it { is_expected.to be_falsey }
      end

      context 'when exit_codes is an empty array' do
        let(:options) do
          {
            allow_failure_criteria: {
              exit_codes: []
            }
          }
        end

        it { is_expected.to be_falsey }
      end

      context 'when exit_codes are defined' do
        let(:options) do
          {
            allow_failure_criteria: {
              exit_codes: [5, 6]
            }
          }
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'with retry' do
      context 'when exit_codes is nil' do
        let(:options) do
          {
            retry: {
              exit_codes: nil
            }
          }
        end

        it { is_expected.to be_falsey }
      end

      context 'when exit_codes is an empty array' do
        let(:options) do
          {
            retry: {
              exit_codes: []
            }
          }
        end

        it { is_expected.to be_falsey }
      end

      context 'when exit_codes are defined' do
        let(:options) do
          {
            retry: {
              exit_codes: [5, 6]
            }
          }
        end

        it { is_expected.to be_truthy }
      end
    end

    context "with exit_codes defined for retry and allow_failure_criteria" do
      let(:options) do
        {
          allow_failure_criteria: {
            exit_codes: [1]
          },
          retry: {
            exit_codes: [5, 6]
          }
        }
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '.build_matchers' do
    let_it_be(:pipeline) { create(:ci_pipeline, :protected, project: project) }

    subject(:matchers) { pipeline.builds.build_matchers(pipeline.project) }

    context 'when the pipeline is empty' do
      it 'does not throw errors' do
        is_expected.to eq([])
      end
    end

    context 'when the pipeline has builds' do
      let_it_be(:build_without_tags) do
        create(:ci_build, pipeline: pipeline)
      end

      let_it_be(:build_with_tags) do
        create(:ci_build, pipeline: pipeline, tag_list: %w[tag1 tag2])
      end

      let_it_be(:other_build_with_tags) do
        create(:ci_build, pipeline: pipeline, tag_list: %w[tag2 tag1])
      end

      it { expect(matchers.size).to eq(2) }

      it 'groups build ids' do
        expect(matchers.map(&:build_ids)).to match_array(
          [
            [build_without_tags.id],
            match_array([build_with_tags.id, other_build_with_tags.id])
          ])
      end

      it { expect(matchers.map(&:tag_list)).to match_array([[], %w[tag1 tag2]]) }

      it { expect(matchers.map(&:protected?)).to all be_falsey }

      context 'when the builds are protected' do
        before do
          pipeline.builds.update_all(protected: true)
        end

        it { expect(matchers).to all be_protected }
      end
    end
  end

  describe '#build_matcher' do
    let_it_be(:build) do
      build_stubbed(:ci_build, tag_list: %w[tag1 tag2], pipeline: pipeline)
    end

    subject(:matcher) { build.build_matcher }

    it { expect(matcher.build_ids).to eq([build.id]) }

    it { expect(matcher.tag_list).to match_array(%w[tag1 tag2]) }

    it { expect(matcher.protected?).to eq(build.protected?) }

    it { expect(matcher.project).to eq(build.project) }
  end

  describe '#shared_runner_build?' do
    context 'when build does not have a runner assigned' do
      it 'is not a shared runner build' do
        expect(build.runner).to be_nil

        expect(build).not_to be_shared_runner_build
      end
    end

    context 'when build has a project runner assigned' do
      before do
        build.runner = create(:ci_runner, :project, projects: [project])
      end

      it 'is not a shared runner build' do
        expect(build).not_to be_shared_runner_build
      end
    end

    context 'when build has an instance runner assigned' do
      before do
        build.runner = create(:ci_runner, :instance_type)
      end

      it 'is a shared runner build' do
        expect(build).to be_shared_runner_build
      end
    end
  end

  describe '.with_project_and_metadata' do
    it 'does not join across databases' do
      with_cross_joins_prevented do
        ::Ci::Build.with_project_and_metadata.to_a
      end
    end
  end

  describe '.without_coverage' do
    let!(:build_with_coverage) { create(:ci_build, pipeline: pipeline, coverage: 100.0) }

    it 'returns builds without coverage values' do
      expect(described_class.without_coverage).to eq([build])
    end
  end

  describe '.with_coverage_regex' do
    let!(:build_with_coverage_regex) { create(:ci_build, pipeline: pipeline, coverage_regex: '\d') }

    it 'returns builds with coverage regex values' do
      expect(described_class.with_coverage_regex).to eq([build_with_coverage_regex])
    end
  end

  describe '#ensure_trace_metadata!' do
    it 'delegates to Ci::BuildTraceMetadata' do
      expect(Ci::BuildTraceMetadata)
        .to receive(:find_or_upsert_for!)
        .with(build.id, build.partition_id)

      build.ensure_trace_metadata!
    end
  end

  describe '#doom!' do
    subject { build.doom! }

    let(:traits) { [] }
    let(:build) do
      travel(-1.minute) do
        create(:ci_build, *traits, pipeline: pipeline)
      end
    end

    it 'updates status, failure_reason, finished_at and updated_at', :aggregate_failures do
      old_timestamp = build.updated_at

      new_timestamp = \
        freeze_time do
          Time.current.tap do
            subject
          end
        end

      expect(old_timestamp).not_to eq(new_timestamp)
      expect(build.updated_at).to eq(new_timestamp)
      expect(build.finished_at).to eq(new_timestamp)
      expect(build.status).to eq("failed")
      expect(build.failure_reason).to eq("data_integrity_failure")
    end

    it 'logs a message and increments the job failure counter', :aggregate_failures do
      expect(::Gitlab::Ci::Pipeline::Metrics.job_failure_reason_counter)
        .to(receive(:increment))
        .with(reason: :data_integrity_failure)

      expect(Gitlab::AppLogger)
        .to receive(:info)
        .with(a_hash_including(message: 'Build doomed', class: build.class.name, build_id: build.id))
        .and_call_original

      subject
    end

    context 'with deployment' do
      let(:environment) { create(:environment) }
      let(:build) { create(:ci_build, :with_deployment, environment: environment.name, pipeline: pipeline) }

      it 'updates the deployment status', :aggregate_failures do
        expect(build.deployment).to receive(:sync_status_with).with(build).and_call_original

        subject

        expect(build.deployment.reload.status).to eq("failed")
      end
    end

    context 'with queued builds' do
      let(:traits) { [:queued] }

      it 'drops associated pending build' do
        subject

        expect(build.reload.queuing_entry).not_to be_present
      end
    end

    context 'with running builds' do
      let(:traits) { [:picked] }

      it 'drops associated runtime metadata', :aggregate_failures do
        subject

        expect(build.reload.runtime_metadata).not_to be_present
      end
    end

    context 'finished builds' do
      let(:traits) { [:finished] }

      it 'does not update finished_at' do
        expect { subject }.not_to change { build.reload.finished_at }
      end
    end
  end

  it 'does not generate cross DB queries when a record is created via FactoryBot' do
    with_cross_database_modification_prevented do
      create(:ci_build, pipeline: pipeline)
    end
  end

  describe '#supports_canceling?' do
    let(:job) { create(:ci_build, :running, project: project) }

    context 'when the builds runner does not support canceling' do
      specify { expect(job.supports_canceling?).to be false }
    end

    context 'when the builds runner supports canceling' do
      include_context 'when canceling support'

      it 'returns true' do
        expect(job.supports_canceling?).to be true
      end
    end
  end

  describe '#runtime_runner_features' do
    subject do
      build.save!
      build.reload.cancel_gracefully?
    end

    let(:build) { create(:ci_build, pipeline: pipeline) }

    it 'cannot cancel gracefully' do
      expect(subject).to be false
    end

    it 'can cancel gracefully' do
      build.set_cancel_gracefully

      expect(subject).to be true
    end
  end

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :ci_build }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_build, user: create(:user), pipeline: pipeline) }
    let!(:parent) { model.user }
  end

  describe '#clone' do
    let_it_be(:user) { create(:user) }

    context 'when build execution config is given' do
      let(:build_execution_config) { create(:ci_builds_execution_configs, pipeline: pipeline) }

      it 'clones the config id' do
        build = create(:ci_build, pipeline: pipeline, execution_config: build_execution_config)

        new_build = build.clone(current_user: user)
        new_build.save!

        expect(new_build.execution_config_id).to eq(build_execution_config.id)
      end
    end

    context 'when given new job variables' do
      context 'when the cloned build has an action' do
        it 'applies the new job variables' do
          build = create(:ci_build, :actionable, pipeline: pipeline)
          create(:ci_job_variable, job: build, key: 'TEST_KEY', value: 'old value')
          create(:ci_job_variable, job: build, key: 'OLD_KEY', value: 'i will not live for long')

          new_build = build.clone(current_user: user, new_job_variables_attributes:
            [
              { key: 'TEST_KEY', value: 'new value' },
              { key: 'NEW_KEY', value: 'exciting new value' }
            ])
          new_build.save!

          expect(new_build.job_variables.count).to be(2)
          expect(new_build.job_variables.pluck(:key)).to contain_exactly('TEST_KEY', 'NEW_KEY')
          expect(new_build.job_variables.map(&:value)).to contain_exactly('new value', 'exciting new value')
        end
      end

      context 'when the cloned build does not have an action' do
        it 'applies the old job variables' do
          build = create(:ci_build, pipeline: pipeline)
          create(:ci_job_variable, job: build, key: 'TEST_KEY', value: 'old value')

          new_build = build.clone(
            current_user: user,
            new_job_variables_attributes: [{ key: 'TEST_KEY', value: 'new value' }]
          )
          new_build.save!

          expect(new_build.job_variables.count).to be(1)
          expect(new_build.job_variables.pluck(:key)).to contain_exactly('TEST_KEY')
          expect(new_build.job_variables.map(&:value)).to contain_exactly('old value')
        end
      end
    end

    context 'when not given new job variables' do
      it 'applies the old job variables' do
        build = create(:ci_build, pipeline: pipeline)
        create(:ci_job_variable, job: build, key: 'TEST_KEY', value: 'old value')

        new_build = build.clone(current_user: user)
        new_build.save!

        expect(new_build.job_variables.count).to be(1)
        expect(new_build.job_variables.pluck(:key)).to contain_exactly('TEST_KEY')
        expect(new_build.job_variables.map(&:value)).to contain_exactly('old value')
      end
    end
  end

  describe '#test_suite_name' do
    let(:build) { create(:ci_build, name: 'test', pipeline: pipeline) }

    it 'uses the group name for test suite name' do
      expect(build.test_suite_name).to eq('test')
    end

    context 'when build is part of parallel build' do
      let(:build) { create(:ci_build, name: 'build 1/2', pipeline: pipeline) }

      it 'uses the group name for test suite name' do
        expect(build.test_suite_name).to eq('build')
      end
    end

    context 'when build is part of matrix build' do
      let!(:matrix_build) { create(:ci_build, :matrix, pipeline: pipeline) }

      it 'uses the job name for the test suite' do
        expect(matrix_build.test_suite_name).to eq(matrix_build.name)
      end
    end
  end

  describe '#runtime_hooks' do
    let(:build1) do
      FactoryBot.build(
        :ci_build,
        options: { hooks: { pre_get_sources_script: ["echo 'hello pre_get_sources_script'"] } },
        pipeline: pipeline
      )
    end

    subject(:runtime_hooks) { build1.runtime_hooks }

    it 'returns an array of hook objects' do
      expect(runtime_hooks.size).to eq(1)
      expect(runtime_hooks[0].name).to eq('pre_get_sources_script')
      expect(runtime_hooks[0].script).to eq(["echo 'hello pre_get_sources_script'"])
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let(:new_pipeline) { create(:ci_pipeline, project: project) }
    let(:ci_stage) { create(:ci_stage, pipeline: new_pipeline) }
    let(:ci_build) { FactoryBot.build(:ci_build, pipeline: new_pipeline, ci_stage: ci_stage) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns partition_id to job variables successfully', :aggregate_failures do
      ci_build.job_variables_attributes = [
        { key: 'TEST_KEY', value: 'new value' },
        { key: 'NEW_KEY', value: 'exciting new value' }
      ]

      ci_build.save!

      expect(ci_build.job_variables.count).to eq(2)
      expect(ci_build.job_variables.first.partition_id).to eq(ci_testing_partition_id)
      expect(ci_build.job_variables.second.partition_id).to eq(ci_testing_partition_id)
    end
  end

  describe 'assigning token' do
    include Ci::PartitioningHelpers

    let(:new_pipeline) { create(:ci_pipeline, project: project) }
    let(:ci_build) { create(:ci_build, pipeline: new_pipeline) }

    context 'when the token is a JWT' do
      it 'includes the token prefix' do
        expect(ci_build.token).to match(/^glcbt-/)
      end
    end

    context 'when the token is a database token' do
      before do
        stub_feature_flags(ci_job_token_jwt: false)
        stub_current_partition_id(ci_testing_partition_id)
      end

      it 'includes partition_id in the token prefix' do
        prefix = ci_build.token.match(/^glcbt-([\h]+)_/)
        partition_prefix = prefix[1].to_i(16)

        expect(partition_prefix).to eq(ci_testing_partition_id)
      end
    end
  end

  describe '#remove_token!' do
    before do
      stub_feature_flags(ci_job_token_jwt: false)
    end

    it 'removes the token' do
      expect(build.token).to be_present

      build.remove_token!

      expect(build.token).to be_nil
      expect(build.changes).to be_empty
    end
  end

  describe 'metadata partitioning' do
    let(:pipeline) { create(:ci_pipeline, project: project, partition_id: ci_testing_partition_id) }

    let(:ci_stage) { create(:ci_stage, pipeline: pipeline) }
    let(:build) { FactoryBot.build(:ci_build, pipeline: pipeline, ci_stage: ci_stage) }

    it 'creates the metadata record and assigns its partition' do
      # The record is initialized by the factory calling metadatable setters
      build.metadata = nil

      expect(build.metadata).to be_nil

      expect(build.save!).to be_truthy

      expect(build.metadata).to be_present
      expect(build.metadata).to be_valid
      expect(build.metadata.partition_id).to eq(ci_testing_partition_id)
    end
  end

  describe 'secrets management id_tokens usage data' do
    context 'when ID tokens are defined' do
      context 'on create' do
        let(:ci_build) { create(:ci_build, user: user, id_tokens: { 'ID_TOKEN_1' => { aud: 'developers' } }) }

        before do
          allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).and_call_original
        end

        it 'tracks RedisHLL event with user_id' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
            .with('i_ci_secrets_management_id_tokens_build_created', values: user.id)

          ci_build
        end

        it 'tracks Snowplow event with RedisHLL context' do
          params = {
            category: described_class.to_s,
            action: 'create_id_tokens',
            namespace: ci_build.namespace,
            user: user,
            label: 'redis_hll_counters.ci_secrets_management.i_ci_secrets_management_id_tokens_build_created_monthly',
            ultimate_namespace_id: ci_build.namespace.root_ancestor.id,
            context: [Gitlab::Tracking::ServicePingContext.new(
              data_source: :redis_hll,
              event: 'i_ci_secrets_management_id_tokens_build_created'
            ).to_context.to_json]
          }

          ci_build
          expect_snowplow_event(**params)
        end
      end

      context 'on update' do
        let_it_be(:ci_build) { create(:ci_build, user: user, id_tokens: { 'ID_TOKEN_1' => { aud: 'developers' } }) }

        it 'does not track RedisHLL event' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

          ci_build.success
        end

        it 'does not track Snowplow event' do
          ci_build.success

          expect_no_snowplow_event
        end
      end
    end

    context 'when ID tokens are not defined' do
      let(:ci_build) { create(:ci_build, user: user) }

      context 'on create' do
        it 'does not track RedisHLL event' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)
            .with('i_ci_secrets_management_id_tokens_build_created', values: user.id)

          ci_build
        end

        it 'does not track Snowplow event' do
          ci_build.save!
          expect_no_snowplow_event
        end
      end
    end
  end

  describe 'job artifact associations' do
    Ci::JobArtifact.file_types.each do |type, _|
      method = "job_artifacts_#{type}"

      describe "##{method}" do
        subject { build.send(method) }

        context "when job has an artifact of type #{type}" do
          let!(:artifact) do
            create(
              :ci_job_artifact,
              job: build,
              file_type: type,
              file_format: Enums::Ci::JobArtifact.type_and_format_pairs[type.to_sym]
            )
          end

          it { is_expected.to eq(artifact) }
        end

        context "when job has no artifact of type #{type}" do
          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe 'TokenAuthenticatable' do
    before do
      stub_feature_flags(ci_job_token_jwt: false)
    end

    it_behaves_like 'TokenAuthenticatable' do
      let(:token_field) { :token }
    end

    describe 'token format for builds transiting into pending' do
      let(:partition_id) { 100 }
      let(:ci_build) { described_class.new(partition_id: partition_id) }

      context 'when build is initialized without a token and transits to pending' do
        let(:partition_id_prefix_in_16_bit_encode) { partition_id.to_s(16) + '_' }

        it 'generates a token' do
          expect { ci_build.enqueue }
            .to change { ci_build.token }.from(nil).to(a_string_starting_with("glcbt-#{partition_id_prefix_in_16_bit_encode}"))
        end
      end

      context 'when build is initialized with a token and transits to pending' do
        let(:token) { 'an_existing_secret_token' }

        before do
          ci_build.set_token(token)
        end

        it 'does not change the existing token' do
          expect { ci_build.enqueue }
            .not_to change { ci_build.token }.from(token)
        end
      end
    end

    describe '#prefix_and_partition_for_token' do
      # 100.to_s(16) -> 64
      let(:ci_build) { described_class.new(partition_id: 100) }

      it 'is prefixed with static string and partition id' do
        ci_build.ensure_token
        expect(ci_build.token).to match(/^glcbt-64_[\w-]{20}$/)
      end
    end
  end

  describe '#source' do
    it 'defaults to the pipeline source name' do
      expect(build.source).to eq(build.pipeline.source)
    end

    it 'returns the associated source name when present' do
      create(:ci_build_source, build: build, source: 'scan_execution_policy')

      expect(build.source).to eq('scan_execution_policy')
    end
  end

  describe '#token' do
    subject(:token) { build.token }

    let(:jwt_token) { 'the-jwt-token' }
    let(:database_token) { 'the-db-token' }

    before do
      allow(::Ci::JobToken::Jwt).to receive(:encode).with(build).and_return(jwt_token)
    end

    it { is_expected.to eq(jwt_token) }

    context 'when ci_job_token_jwt feature flag is disabled' do
      before do
        stub_feature_flags(ci_job_token_jwt: false)
        build.set_token(database_token)
      end

      it { is_expected.to eq(database_token) }

      context 'when job user requires composite identity' do
        before do
          allow(build).to receive_message_chain(:user, :has_composite_identity?).and_return(true)
        end

        it { is_expected.to eq(jwt_token) }
      end
    end
  end

  describe '#valid_token?' do
    subject { build.valid_token?(token) }

    let_it_be(:build) { create(:ci_build, :running) }
    let(:token) { build.token }

    it { is_expected.to be(true) }

    context 'when the token is a database token' do
      before do
        stub_feature_flags(ci_job_token_jwt: false)
      end

      it { is_expected.to be(true) }
    end
  end
end
