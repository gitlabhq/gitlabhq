# frozen_string_literal: true

require 'spec_helper'

describe Ci::Build do
  set(:user) { create(:user) }
  set(:group) { create(:group) }
  set(:project) { create(:project, :repository, group: group) }

  set(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:build) { create(:ci_build, pipeline: pipeline) }

  it { is_expected.to belong_to(:runner) }
  it { is_expected.to belong_to(:trigger_request) }
  it { is_expected.to belong_to(:erased_by) }

  it { is_expected.to have_many(:trace_sections) }
  it { is_expected.to have_many(:needs) }
  it { is_expected.to have_many(:sourced_pipelines) }
  it { is_expected.to have_many(:job_variables) }

  it { is_expected.to have_one(:deployment) }
  it { is_expected.to have_one(:runner_session) }

  it { is_expected.to validate_presence_of(:ref) }

  it { is_expected.to respond_to(:has_trace?) }
  it { is_expected.to respond_to(:trace) }

  it { is_expected.to delegate_method(:merge_request_event?).to(:pipeline) }
  it { is_expected.to delegate_method(:merge_request_ref?).to(:pipeline) }
  it { is_expected.to delegate_method(:legacy_detached_merge_request_pipeline?).to(:pipeline) }

  it { is_expected.to include_module(Ci::PipelineDelegator) }

  describe 'associations' do
    it 'has a bidirectional relationship with projects' do
      expect(described_class.reflect_on_association(:project).has_inverse?).to eq(:builds)
      expect(Project.reflect_on_association(:builds).has_inverse?).to eq(:project)
    end
  end

  describe 'callbacks' do
    context 'when running after_create callback' do
      it 'triggers asynchronous build hooks worker' do
        expect(BuildHooksWorker).to receive(:perform_async)

        create(:ci_build)
      end
    end
  end

  describe 'status' do
    context 'when transitioning to any state from running' do
      it 'removes runner_session' do
        %w(success drop cancel).each do |event|
          build = FactoryBot.create(:ci_build, :running, :with_runner_session, pipeline: pipeline)

          build.fire_events!(event)

          expect(build.reload.runner_session).to be_nil
        end
      end
    end
  end

  describe '.manual_actions' do
    let!(:manual_but_created) { create(:ci_build, :manual, status: :created, pipeline: pipeline) }
    let!(:manual_but_succeeded) { create(:ci_build, :manual, status: :success, pipeline: pipeline) }
    let!(:manual_action) { create(:ci_build, :manual, pipeline: pipeline) }

    subject { described_class.manual_actions }

    it { is_expected.to include(manual_action) }
    it { is_expected.to include(manual_but_succeeded) }
    it { is_expected.not_to include(manual_but_created) }
  end

  describe '.ref_protected' do
    subject { described_class.ref_protected }

    context 'when protected is true' do
      let!(:job) { create(:ci_build, :protected) }

      it { is_expected.to include(job) }
    end

    context 'when protected is false' do
      let!(:job) { create(:ci_build) }

      it { is_expected.not_to include(job) }
    end

    context 'when protected is nil' do
      let!(:job) { create(:ci_build) }

      before do
        job.update_attribute(:protected, nil)
      end

      it { is_expected.not_to include(job) }
    end
  end

  describe '.with_artifacts_archive' do
    subject { described_class.with_artifacts_archive }

    context 'when job does not have an archive' do
      let!(:job) { create(:ci_build) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end

    context 'when job has a job artifact archive' do
      let!(:job) { create(:ci_build, :artifacts) }

      it 'returns the job' do
        is_expected.to include(job)
      end
    end

    context 'when job has a job artifact trace' do
      let!(:job) { create(:ci_build, :trace_artifact) }

      it 'does not return the job' do
        is_expected.not_to include(job)
      end
    end
  end

  describe '.with_live_trace' do
    subject { described_class.with_live_trace }

    context 'when build has live trace' do
      let!(:build) { create(:ci_build, :success, :trace_live) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build does not have live trace' do
      let!(:build) { create(:ci_build, :success, :trace_artifact) }

      it 'does not select the build' do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_stale_live_trace' do
    subject { described_class.with_stale_live_trace }

    context 'when build has a stale live trace' do
      let!(:build) { create(:ci_build, :success, :trace_live, finished_at: 1.day.ago) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build does not have a stale live trace' do
      let!(:build) { create(:ci_build, :success, :trace_live, finished_at: 1.hour.ago) }

      it 'does not select the build' do
        is_expected.to be_empty
      end
    end
  end

  describe '.finished_before' do
    subject { described_class.finished_before(date) }

    let(:date) { 1.hour.ago }

    context 'when build has finished one day ago' do
      let!(:build) { create(:ci_build, :success, finished_at: 1.day.ago) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build has finished 30 minutes ago' do
      let!(:build) { create(:ci_build, :success, finished_at: 30.minutes.ago) }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'when build is still running' do
      let!(:build) { create(:ci_build, :running) }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.with_exposed_artifacts' do
    subject { described_class.with_exposed_artifacts }

    let!(:job1) { create(:ci_build) }
    let!(:job2) { create(:ci_build, options: options) }
    let!(:job3) { create(:ci_build) }

    context 'when some jobs have exposed artifacs and some not' do
      let(:options) { { artifacts: { expose_as: 'test', paths: ['test'] } } }

      before do
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

  describe '.with_reports' do
    subject { described_class.with_reports(Ci::JobArtifact.test_reports) }

    context 'when build has a test report' do
      let!(:build) { create(:ci_build, :success, :test_reports) }

      it 'selects the build' do
        is_expected.to eq([build])
      end
    end

    context 'when build does not have test reports' do
      let!(:build) { create(:ci_build, :success, :trace_artifact) }

      it 'does not select the build' do
        is_expected.to be_empty
      end
    end

    context 'when there are multiple builds with test reports' do
      let!(:builds) { create_list(:ci_build, 5, :success, :test_reports) }

      it 'does not execute a query for selecting job artifact one by one' do
        recorded = ActiveRecord::QueryRecorder.new do
          subject.each do |build|
            build.job_artifacts.map { |a| a.file.exists? }
          end
        end

        expect(recorded.count).to eq(2)
      end
    end
  end

  describe '.with_needs' do
    let!(:build) { create(:ci_build) }
    let!(:build_b) { create(:ci_build) }
    let!(:build_need_a) { create(:ci_build_need, build: build) }
    let!(:build_need_b) { create(:ci_build_need, build: build_b) }

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
    let!(:build) { create(:ci_build) }

    subject { described_class.without_needs }

    context 'when no build_need is created' do
      it { is_expected.to contain_exactly(build) }
    end

    context 'when a build_need is created' do
      let!(:need_a) { create(:ci_build_need, build: build) }

      it { is_expected.to be_empty }
    end
  end

  describe '#enqueue' do
    let(:build) { create(:ci_build, :created) }

    subject { build.enqueue }

    before do
      allow(build).to receive(:any_unmet_prerequisites?).and_return(has_prerequisites)
      allow(Ci::PrepareBuildService).to receive(:perform_async)
    end

    context 'build has unmet prerequisites' do
      let(:has_prerequisites) { true }

      it 'transitions to preparing' do
        subject

        expect(build).to be_preparing
      end
    end

    context 'build has no prerequisites' do
      let(:has_prerequisites) { false }

      it 'transitions to pending' do
        subject

        expect(build).to be_pending
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

  describe '#schedulable?' do
    subject { build.schedulable? }

    context 'when build is schedulable' do
      let(:build) { create(:ci_build, :created, :schedulable, project: project) }

      it { expect(subject).to be_truthy }
    end

    context 'when build is not schedulable' do
      let(:build) { create(:ci_build, :created, project: project) }

      it { expect(subject).to be_falsy }
    end
  end

  describe '#schedule' do
    subject { build.schedule }

    before do
      project.add_developer(user)
    end

    let(:build) { create(:ci_build, :created, :schedulable, user: user, project: project) }

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
      Timecop.freeze do
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

    let(:build) { build_stubbed(:ci_build, options: option) }

    context 'when start_in is 1 day' do
      let(:option) { { start_in: '1 day' } }

      it 'returns date after 1 day' do
        Timecop.freeze do
          is_expected.to eq(1.day.since)
        end
      end
    end

    context 'when start_in is 1 week' do
      let(:option) { { start_in: '1 week' } }

      it 'returns date after 1 week' do
        Timecop.freeze do
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

  describe '#any_runners_online?' do
    subject { build.any_runners_online? }

    context 'when no runners' do
      it { is_expected.to be_falsey }
    end

    context 'when there are runners' do
      let(:runner) { create(:ci_runner, :project, projects: [build.project]) }

      before do
        runner.update(contacted_at: 1.second.ago)
      end

      it { is_expected.to be_truthy }

      it 'that is inactive' do
        runner.update(active: false)
        is_expected.to be_falsey
      end

      it 'that is not online' do
        runner.update(contacted_at: nil)
        is_expected.to be_falsey
      end

      it 'that cannot handle build' do
        expect_any_instance_of(Ci::Runner).to receive(:can_pick?).and_return(false)
        is_expected.to be_falsey
      end
    end
  end

  describe '#artifacts?' do
    subject { build.artifacts? }

    context 'when new artifacts are used' do
      context 'artifacts archive does not exist' do
        let(:build) { create(:ci_build) }

        it { is_expected.to be_falsy }
      end

      context 'artifacts archive exists' do
        let(:build) { create(:ci_build, :artifacts) }

        it { is_expected.to be_truthy }

        context 'is expired' do
          let(:build) { create(:ci_build, :artifacts, :expired) }

          it { is_expected.to be_falsy }
        end
      end
    end
  end

  describe '#browsable_artifacts?' do
    subject { build.browsable_artifacts? }

    context 'artifacts metadata does exists' do
      let(:build) { create(:ci_build, :artifacts) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#artifacts_expired?' do
    subject { build.artifacts_expired? }

    context 'is expired' do
      before do
        build.update(artifacts_expire_at: Time.now - 7.days)
      end

      it { is_expected.to be_truthy }
    end

    context 'is not expired' do
      before do
        build.update(artifacts_expire_at: Time.now + 7.days)
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
      let(:build) { create(:ci_build, :artifacts) }
      it { is_expected.to be_truthy }
    end
  end

  describe '#artifacts_expire_in' do
    subject { build.artifacts_expire_in }

    it { is_expected.to be_nil }

    context 'when artifacts_expire_at is specified' do
      let(:expire_at) { Time.now + 7.days }

      before do
        build.artifacts_expire_at = expire_at
      end

      it { is_expected.to be_within(5).of(expire_at - Time.now) }
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
    let(:options) { { cache: { key: "key", paths: ["public"], policy: "pull-push" } } }

    subject { build.cache }

    context 'when build has cache' do
      before do
        allow(build).to receive(:options).and_return(options)
      end

      context 'when project has jobs_cache_index' do
        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(1)
        end

        it { is_expected.to be_an(Array).and all(include(key: "key-1")) }
      end

      context 'when project does not have jobs_cache_index' do
        before do
          allow_any_instance_of(Project).to receive(:jobs_cache_index).and_return(nil)
        end

        it { is_expected.to eq([options[:cache]]) }
      end
    end

    context 'when build does not have cache' do
      before do
        allow(build).to receive(:options).and_return({})
      end

      it { is_expected.to eq([nil]) }
    end
  end

  describe '#depends_on_builds' do
    let!(:build) { create(:ci_build, pipeline: pipeline, name: 'build', stage_idx: 0, stage: 'build') }
    let!(:rspec_test) { create(:ci_build, pipeline: pipeline, name: 'rspec', stage_idx: 1, stage: 'test') }
    let!(:rubocop_test) { create(:ci_build, pipeline: pipeline, name: 'rubocop', stage_idx: 1, stage: 'test') }
    let!(:staging) { create(:ci_build, pipeline: pipeline, name: 'staging', stage_idx: 2, stage: 'deploy') }

    it 'expects to have no dependents if this is first build' do
      expect(build.depends_on_builds).to be_empty
    end

    it 'expects to have one dependent if this is test' do
      expect(rspec_test.depends_on_builds.map(&:id)).to contain_exactly(build.id)
    end

    it 'expects to have all builds from build and test stage if this is last' do
      expect(staging.depends_on_builds.map(&:id)).to contain_exactly(build.id, rspec_test.id, rubocop_test.id)
    end

    it 'expects to have retried builds instead the original ones' do
      project.add_developer(user)

      retried_rspec = described_class.retry(rspec_test, user)

      expect(staging.depends_on_builds.map(&:id))
        .to contain_exactly(build.id, retried_rspec.id, rubocop_test.id)
    end

    describe '#dependencies' do
      let(:dependencies) { }
      let(:needs) { }

      let!(:final) do
        create(:ci_build,
          pipeline: pipeline, name: 'final',
          stage_idx: 3, stage: 'deploy', options: {
            dependencies: dependencies
          }
        )
      end

      before do
        needs.to_a.each do |need|
          create(:ci_build_need, build: final, **need)
        end
      end

      subject { final.dependencies }

      context 'when dependencies are defined' do
        let(:dependencies) { %w(rspec staging) }

        it { is_expected.to contain_exactly(rspec_test, staging) }
      end

      context 'when needs are defined' do
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: true },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(build, rspec_test, staging) }

        context 'when ci_dag_support is disabled' do
          before do
            stub_feature_flags(ci_dag_support: false)
          end

          it { is_expected.to contain_exactly(build, rspec_test, rubocop_test, staging) }
        end
      end

      context 'when need artifacts are defined' do
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: false },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(build, staging) }
      end

      context 'when needs and dependencies are defined' do
        let(:dependencies) { %w(rspec staging) }
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: true },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(rspec_test, staging) }
      end

      context 'when needs and dependencies contradict' do
        let(:dependencies) { %w(rspec staging) }
        let(:needs) do
          [
            { name: 'build',   artifacts: true },
            { name: 'rspec',   artifacts: false },
            { name: 'staging', artifacts: true }
          ]
        end

        it { is_expected.to contain_exactly(staging) }
      end

      context 'when nor dependencies or needs are defined' do
        it { is_expected.to contain_exactly(build, rspec_test, rubocop_test, staging) }
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

  describe '#coverage_regex' do
    subject { build.coverage_regex }

    context 'when project has build_coverage_regex set' do
      let(:project_regex) { '\(\d+\.\d+\) covered' }

      before do
        project.update_column(:build_coverage_regex, project_regex)
      end

      context 'and coverage_regex attribute is not set' do
        it { is_expected.to eq(project_regex) }
      end

      context 'but coverage_regex attribute is also set' do
        let(:build_regex) { 'Code coverage: \d+\.\d+' }

        before do
          build.coverage_regex = build_regex
        end

        it { is_expected.to eq(build_regex) }
      end
    end

    context 'when neither project nor build has coverage regex set' do
      it { is_expected.to be_nil }
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

  describe '#parse_trace_sections!' do
    it 'calls ExtractSectionsFromBuildTraceService' do
      expect(Ci::ExtractSectionsFromBuildTraceService)
          .to receive(:new).with(project, build.user).once.and_call_original
      expect_any_instance_of(Ci::ExtractSectionsFromBuildTraceService)
        .to receive(:execute).with(build).once

      build.parse_trace_sections!
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

    let(:build) { create(:ci_build, :trace_live) }

    it { is_expected.to be_truthy }

    context 'when build does not have live trace' do
      let(:build) { create(:ci_build) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#has_archived_trace?' do
    subject { build.has_archived_trace? }

    let(:build) { create(:ci_build, :trace_artifact) }

    it { is_expected.to be_truthy }

    context 'when build does not have archived trace' do
      let(:build) { create(:ci_build) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#has_job_artifacts?' do
    subject { build.has_job_artifacts? }

    context 'when build has a job artifact' do
      let(:build) { create(:ci_build, :artifacts) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#has_old_trace?' do
    subject { build.has_old_trace? }

    context 'when old trace exists' do
      before do
        build.update_column(:trace, 'old trace')
      end

      it { is_expected.to be_truthy }
    end

    context 'when old trace does not exist' do
      it { is_expected.to be_falsy }
    end
  end

  describe '#trace=' do
    it "expect to fail trace=" do
      expect { build.trace = "new" }.to raise_error(NotImplementedError)
    end
  end

  describe '#old_trace' do
    subject { build.old_trace }

    before do
      build.update_column(:trace, 'old trace')
    end

    it "expect to receive data from database" do
      is_expected.to eq('old trace')
    end
  end

  describe '#erase_old_trace!' do
    subject { build.erase_old_trace! }

    context 'when old trace exists' do
      before do
        build.update_column(:trace, 'old trace')
      end

      it "erases old trace" do
        subject

        expect(build.old_trace).to be_nil
      end

      it "executes UPDATE query" do
        recorded = ActiveRecord::QueryRecorder.new { subject }

        expect(recorded.log.select { |l| l.match?(/UPDATE.*ci_builds/) }.count).to eq(1)
      end
    end

    context 'when old trace does not exist' do
      it 'does not execute UPDATE query' do
        recorded = ActiveRecord::QueryRecorder.new { subject }

        expect(recorded.log.select { |l| l.match?(/UPDATE.*ci_builds/) }.count).to eq(0)
      end
    end
  end

  describe '#hide_secrets' do
    let(:subject) { build.hide_secrets(data) }

    context 'hide runners token' do
      let(:data) { "new #{project.runners_token} data"}

      it { is_expected.to match(/^new x+ data$/) }
    end

    context 'hide build token' do
      let(:data) { "new #{build.token} data"}

      it { is_expected.to match(/^new x+ data$/) }
    end
  end

  describe 'state transition as a deployable' do
    let!(:build) { create(:ci_build, :with_deployment, :start_review_app) }
    let(:deployment) { build.deployment }
    let(:environment) { deployment.environment }

    before do
      allow(Deployments::FinishedWorker).to receive(:perform_async)
    end

    it 'has deployments record with created status' do
      expect(deployment).to be_created
      expect(environment.name).to eq('review/master')
    end

    context 'when transits to running' do
      before do
        build.run!
      end

      it 'transits deployment status to running' do
        expect(deployment).to be_running
      end
    end

    context 'when transits to success' do
      before do
        allow(Deployments::SuccessWorker).to receive(:perform_async)
        build.success!
      end

      it 'transits deployment status to success' do
        expect(deployment).to be_success
      end
    end

    context 'when transits to failed' do
      before do
        build.drop!
      end

      it 'transits deployment status to failed' do
        expect(deployment).to be_failed
      end
    end

    context 'when transits to skipped' do
      before do
        build.skip!
      end

      it 'transits deployment status to canceled' do
        expect(deployment).to be_canceled
      end
    end

    context 'when transits to canceled' do
      before do
        build.cancel!
      end

      it 'transits deployment status to canceled' do
        expect(deployment).to be_canceled
      end
    end
  end

  describe '#on_stop' do
    subject { build.on_stop }

    context 'when a job has a specification that it can be stopped from the other job' do
      let(:build) { create(:ci_build, :start_review_app) }

      it 'returns the other job name' do
        is_expected.to eq('stop_review_app')
      end
    end

    context 'when a job does not have environment information' do
      let(:build) { create(:ci_build) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe 'deployment' do
    describe '#outdated_deployment?' do
      subject { build.outdated_deployment? }

      context 'when build succeeded' do
        let(:build) { create(:ci_build, :success) }
        let!(:deployment) { create(:deployment, :success, deployable: build) }

        context 'current deployment is latest' do
          it { is_expected.to be_falsey }
        end

        context 'current deployment is not latest on environment' do
          let!(:deployment2) { create(:deployment, :success, environment: deployment.environment) }

          it { is_expected.to be_truthy }
        end
      end

      context 'when build failed' do
        let(:build) { create(:ci_build, :failed) }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe 'environment' do
    describe '#has_environment?' do
      subject { build.has_environment? }

      context 'when environment is defined' do
        before do
          build.update(environment: 'review')
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is not defined' do
        before do
          build.update(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#expanded_environment_name' do
      subject { build.expanded_environment_name }

      context 'when environment uses $CI_COMMIT_REF_NAME' do
        let(:build) do
          create(:ci_build,
                 ref: 'master',
                 environment: 'review/$CI_COMMIT_REF_NAME')
        end

        it { is_expected.to eq('review/master') }
      end

      context 'when environment uses yaml_variables containing symbol keys' do
        let(:build) do
          create(:ci_build,
                 yaml_variables: [{ key: :APP_HOST, value: 'host' }],
                 environment: 'review/$APP_HOST')
        end

        it { is_expected.to eq('review/host') }
      end

      context 'when using persisted variables' do
        let(:build) do
          create(:ci_build, environment: 'review/x$CI_BUILD_ID')
        end

        it { is_expected.to eq('review/x') }
      end
    end

    describe '#expanded_kubernetes_namespace' do
      let(:build) { create(:ci_build, environment: environment, options: options) }

      subject { build.expanded_kubernetes_namespace }

      context 'environment and namespace are not set' do
        let(:environment) { nil }
        let(:options) { nil }

        it { is_expected.to be_nil }
      end

      context 'environment is specified' do
        let(:environment) { 'production' }

        context 'namespace is not set' do
          let(:options) { nil }

          it { is_expected.to be_nil }
        end

        context 'namespace is provided' do
          let(:options) do
            {
              environment: {
                name: environment,
                kubernetes: {
                  namespace: namespace
                }
              }
            }
          end

          context 'with a static value' do
            let(:namespace) { 'production' }

            it { is_expected.to eq namespace }
          end

          context 'with a dynamic value' do
            let(:namespace) { 'deploy-$CI_COMMIT_REF_NAME'}

            it { is_expected.to eq 'deploy-master' }
          end
        end
      end
    end

    describe '#starts_environment?' do
      subject { build.starts_environment? }

      context 'when environment is defined' do
        before do
          build.update(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_truthy }
        end

        context 'and start action is defined' do
          before do
            build.update(options: { environment: { action: 'start' } } )
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          build.update(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#requires_resource?' do
      subject { build.requires_resource? }

      context 'when build needs a resource from a resource group' do
        let(:resource_group) { create(:ci_resource_group, project: project) }
        let(:build) { create(:ci_build, resource_group: resource_group, project: project) }

        context 'when build has not retained a resource' do
          it { is_expected.to eq(true) }
        end

        context 'when build has retained a resource' do
          before do
            resource_group.retain_resource_for(build)
          end

          it { is_expected.to eq(false) }

          context 'when ci_resource_group feature flag is disabled' do
            before do
              stub_feature_flags(ci_resource_group: false)
            end

            it { is_expected.to eq(false) }
          end
        end
      end

      context 'when build does not need a resource from a resource group' do
        let(:build) { create(:ci_build, project: project) }

        it { is_expected.to eq(false) }
      end
    end

    describe '#retains_resource?' do
      subject { build.retains_resource? }

      context 'when build needs a resource from a resource group' do
        let(:resource_group) { create(:ci_resource_group, project: project) }
        let(:build) { create(:ci_build, resource_group: resource_group, project: project) }

        context 'when build has retained a resource' do
          before do
            resource_group.retain_resource_for(build)
          end

          it { is_expected.to eq(true) }
        end

        context 'when build has not retained a resource' do
          it { is_expected.to eq(false) }
        end
      end

      context 'when build does not need a resource from a resource group' do
        let(:build) { create(:ci_build, project: project) }

        it { is_expected.to eq(false) }
      end
    end

    describe '#stops_environment?' do
      subject { build.stops_environment? }

      context 'when environment is defined' do
        before do
          build.update(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_falsey }
        end

        context 'and stop action is defined' do
          before do
            build.update(options: { environment: { action: 'stop' } } )
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          build.update(environment: nil)
        end

        it { is_expected.to be_falsey }
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
      let!(:build) { create(:ci_build) }

      describe '#erase' do
        subject { build.erase }

        it { is_expected.to be false }
      end

      describe '#erasable?' do
        subject { build.erasable? }

        it { is_expected.to eq false }
      end
    end

    context 'build is erasable' do
      context 'new artifacts' do
        let!(:build) { create(:ci_build, :test_reports, :trace_artifact, :success, :artifacts) }

        describe '#erase' do
          before do
            build.erase(erased_by: erased_by)
          end

          context 'erased by user' do
            let!(:erased_by) { create(:user, username: 'eraser') }

            include_examples 'erasable'

            it 'records user who erased a build' do
              expect(build.erased_by).to eq erased_by
            end
          end

          context 'erased by system' do
            let(:erased_by) { nil }

            include_examples 'erasable'

            it 'does not set user who erased a build' do
              expect(build.erased_by).to be_nil
            end
          end
        end

        describe '#erasable?' do
          subject { build.erasable? }

          it { is_expected.to be_truthy }
        end

        describe '#erased?' do
          let!(:build) { create(:ci_build, :trace_artifact, :success, :artifacts) }
          subject { build.erased? }

          context 'job has not been erased' do
            it { is_expected.to be_falsey }
          end

          context 'job has been erased' do
            before do
              build.erase
            end

            it { is_expected.to be_truthy }
          end
        end

        context 'metadata and build trace are not available' do
          let!(:build) { create(:ci_build, :success, :artifacts) }

          before do
            build.erase_erasable_artifacts!
          end

          describe '#erase' do
            it 'does not raise error' do
              expect { build.erase }.not_to raise_error
            end
          end
        end
      end
    end
  end

  describe '#erase_erasable_artifacts!' do
    let!(:build) { create(:ci_build, :success) }

    subject { build.erase_erasable_artifacts! }

    before do
      Ci::JobArtifact.file_types.keys.each do |file_type|
        create(:ci_job_artifact, job: build, file_type: file_type, file_format: Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS[file_type.to_sym])
      end
    end

    it "erases erasable artifacts" do
      subject

      expect(build.job_artifacts.erasable).to be_empty
    end

    it "keeps non erasable artifacts" do
      subject

      Ci::JobArtifact::NON_ERASABLE_FILE_TYPES.each do |file_type|
        expect(build.send("job_artifacts_#{file_type}")).not_to be_nil
      end
    end
  end

  describe '#first_pending' do
    let!(:first) { create(:ci_build, pipeline: pipeline, status: 'pending', created_at: Date.yesterday) }
    let!(:second) { create(:ci_build, pipeline: pipeline, status: 'pending') }
    subject { described_class.first_pending }

    it { is_expected.to be_a(described_class) }
    it('returns with the first pending build') { is_expected.to eq(first) }
  end

  describe '#failed_but_allowed?' do
    subject { build.failed_but_allowed? }

    context 'when build is not allowed to fail' do
      before do
        build.allow_failure = false
      end

      context 'and build.status is success' do
        before do
          build.status = 'success'
        end

        it { is_expected.to be_falsey }
      end

      context 'and build.status is failed' do
        before do
          build.status = 'failed'
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when build is allowed to fail' do
      before do
        build.allow_failure = true
      end

      context 'and build.status is success' do
        before do
          build.status = 'success'
        end

        it { is_expected.to be_falsey }
      end

      context 'and build status is failed' do
        before do
          build.status = 'failed'
        end

        it { is_expected.to be_truthy }
      end

      context 'when build is a manual action' do
        before do
          build.status = 'manual'
        end

        it { is_expected.to be_falsey }
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
          let(:build) { create(:ci_build, :created) }

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

    describe '#retryable?' do
      subject { build }

      context 'when build is retryable' do
        context 'when build is successful' do
          before do
            build.success!
          end

          it { is_expected.to be_retryable }
        end

        context 'when build is failed' do
          before do
            build.drop!
          end

          it { is_expected.to be_retryable }
        end

        context 'when build is canceled' do
          before do
            build.cancel!
          end

          it { is_expected.to be_retryable }
        end
      end

      context 'when build is not retryable' do
        context 'when build is running' do
          before do
            build.run!
          end

          it { is_expected.not_to be_retryable }
        end

        context 'when build is skipped' do
          before do
            build.skip!
          end

          it { is_expected.not_to be_retryable }
        end

        context 'when build is degenerated' do
          before do
            build.degenerate!
          end

          it { is_expected.not_to be_retryable }
        end
      end
    end

    describe '#action?' do
      before do
        build.update(when: value)
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
  end

  describe '#has_tags?' do
    context 'when build has tags' do
      subject { create(:ci_build, tag_list: ['tag']) }

      it { is_expected.to have_tags }
    end

    context 'when build does not have tags' do
      subject { create(:ci_build, tag_list: []) }

      it { is_expected.not_to have_tags }
    end
  end

  describe 'build auto retry feature' do
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

    describe '#options_retry_max' do
      context 'with retries max config option' do
        subject { create(:ci_build, options: { retry: { max: 1 } }) }

        context 'when build_metadata_config is set' do
          before do
            stub_feature_flags(ci_build_metadata_config: true)
          end

          it 'returns the number of configured max retries' do
            expect(subject.options_retry_max).to eq 1
          end
        end

        context 'when build_metadata_config is not set' do
          before do
            stub_feature_flags(ci_build_metadata_config: false)
          end

          it 'returns the number of configured max retries' do
            expect(subject.options_retry_max).to eq 1
          end
        end
      end

      context 'without retries max config option' do
        subject { create(:ci_build) }

        it 'returns nil' do
          expect(subject.options_retry_max).to be_nil
        end
      end

      context 'when build is degenerated' do
        subject { create(:ci_build, :degenerated) }

        it 'returns nil' do
          expect(subject.options_retry_max).to be_nil
        end
      end

      context 'with integer only config option' do
        subject { create(:ci_build, options: { retry: 1 }) }

        it 'returns the number of configured max retries' do
          expect(subject.options_retry_max).to eq 1
        end
      end
    end

    describe '#options_retry_when' do
      context 'with retries when config option' do
        subject { create(:ci_build, options: { retry: { when: ['some_reason'] } }) }

        it 'returns the configured when' do
          expect(subject.options_retry_when).to eq ['some_reason']
        end
      end

      context 'without retries when config option' do
        subject { create(:ci_build) }

        it 'returns always array' do
          expect(subject.options_retry_when).to eq ['always']
        end
      end

      context 'with integer only config option' do
        subject { create(:ci_build, options: { retry: 1 }) }

        it 'returns always array' do
          expect(subject.options_retry_when).to eq ['always']
        end
      end
    end

    describe '#retry_failure?' do
      using RSpec::Parameterized::TableSyntax

      let(:build) { create(:ci_build) }

      subject { build.retry_failure? }

      where(:description, :retry_count, :options, :failure_reason, :result) do
        "retries are disabled" | 0 | { max: 0 } | nil | false
        "max equals count" | 2 | { max: 2 } | nil | false
        "max is higher than count" | 1 | { max: 2 } | nil | true
        "matching failure reason" | 0 | { when: %w[api_failure], max: 2 } | :api_failure | true
        "not matching with always" | 0 | { when: %w[always], max: 2 } | :api_failure | true
        "not matching reason" | 0 | { when: %w[script_error], max: 2 } | :api_failure | false
        "scheduler failure override" | 1 | { when: %w[scheduler_failure], max: 1 } | :scheduler_failure | false
        "default for scheduler failure" | 1 | {} | :scheduler_failure | true
      end

      with_them do
        before do
          allow(build).to receive(:retries_count) { retry_count }

          build.options[:retry] = options
          build.failure_reason = failure_reason
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#keep_artifacts!' do
    let(:build) { create(:ci_build, artifacts_expire_at: Time.now + 7.days) }

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

  describe '#artifacts_file_for_type' do
    let(:build) { create(:ci_build, :artifacts) }
    let(:file_type) { :archive }

    subject { build.artifacts_file_for_type(file_type) }

    it 'queries artifacts for type' do
      expect(build).to receive_message_chain(:job_artifacts, :find_by).with(file_type: Ci::JobArtifact.file_types[file_type])

      subject
    end
  end

  describe '#merge_request' do
    def create_mr(build, pipeline, factory: :merge_request, created_at: Time.now)
      create(factory, source_project: pipeline.project,
                      target_project: pipeline.project,
                      source_branch: build.ref,
                      created_at: created_at)
    end

    context 'when a MR has a reference to the pipeline' do
      before do
        @merge_request = create_mr(build, pipeline, factory: :merge_request)

        commits = [double(id: pipeline.sha)]
        allow(@merge_request).to receive(:commits).and_return(commits)
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request])
      end

      it 'returns the single associated MR' do
        expect(build.merge_request.id).to eq(@merge_request.id)
      end
    end

    context 'when there is not a MR referencing the pipeline' do
      it 'returns nil' do
        expect(build.merge_request).to be_nil
      end
    end

    context 'when more than one MR have a reference to the pipeline' do
      before do
        @merge_request = create_mr(build, pipeline, factory: :merge_request)
        @merge_request.close!
        @merge_request2 = create_mr(build, pipeline, factory: :merge_request)

        commits = [double(id: pipeline.sha)]
        allow(@merge_request).to receive(:commits).and_return(commits)
        allow(@merge_request2).to receive(:commits).and_return(commits)
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request, @merge_request2])
      end

      it 'returns the first MR' do
        expect(build.merge_request.id).to eq(@merge_request.id)
      end
    end

    context 'when a Build is created after the MR' do
      before do
        @merge_request = create_mr(build, pipeline, factory: :merge_request_with_diffs)
        pipeline2 = create(:ci_pipeline, project: project)
        @build2 = create(:ci_build, pipeline: pipeline2)

        allow(@merge_request).to receive(:commit_shas)
          .and_return([pipeline.sha, pipeline2.sha])
        allow(MergeRequest).to receive_message_chain(:includes, :where, :reorder).and_return([@merge_request])
      end

      it 'returns the current MR' do
        expect(@build2.merge_request.id).to eq(@merge_request.id)
      end
    end
  end

  describe '#options' do
    let(:options) do
      {
        image: "ruby:2.1",
        services: ["postgres"],
        script: ["ls -a"]
      }
    end

    it 'contains options' do
      expect(build.options).to eq(options.stringify_keys)
    end

    it 'allows to access with keys' do
      expect(build.options[:image]).to eq('ruby:2.1')
    end

    it 'allows to access with strings' do
      expect(build.options['image']).to eq('ruby:2.1')
    end

    context 'when ci_build_metadata_config is set' do
      before do
        stub_feature_flags(ci_build_metadata_config: true)
      end

      it 'persist data in build metadata' do
        expect(build.metadata.read_attribute(:config_options)).to eq(options.stringify_keys)
      end

      it 'does not persist data in build' do
        expect(build.read_attribute(:options)).to be_nil
      end
    end

    context 'when ci_build_metadata_config is disabled' do
      before do
        stub_feature_flags(ci_build_metadata_config: false)
      end

      it 'persist data in build' do
        expect(build.read_attribute(:options)).to eq(options.symbolize_keys)
      end

      it 'does not persist data in build metadata' do
        expect(build.metadata.read_attribute(:config_options)).to be_nil
      end
    end

    context 'when options include artifacts:expose_as' do
      let(:build) { create(:ci_build, options: { artifacts: { expose_as: 'test' } }) }

      it 'saves the presence of expose_as into build metadata' do
        expect(build.metadata).to have_exposed_artifacts
      end
    end
  end

  describe '#other_manual_actions' do
    let(:build) { create(:ci_build, :manual, pipeline: pipeline) }
    let!(:other_build) { create(:ci_build, :manual, pipeline: pipeline, name: 'other action') }

    subject { build.other_manual_actions }

    before do
      project.add_developer(user)
    end

    it 'returns other actions' do
      is_expected.to contain_exactly(other_build)
    end

    context 'when build is retried' do
      let!(:new_build) { described_class.retry(build, user) }

      it 'does not return any of them' do
        is_expected.not_to include(build, new_build)
      end
    end

    context 'when other build is retried' do
      let!(:retried_build) { described_class.retry(other_build, user) }

      before do
        retried_build.success
      end

      it 'returns a retried build' do
        is_expected.to contain_exactly(retried_build)
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

  describe '#persisted_environment' do
    let!(:environment) do
      create(:environment, project: project, name: "foo-#{project.default_branch}")
    end

    subject { build.persisted_environment }

    context 'when referenced literally' do
      let(:build) do
        create(:ci_build, pipeline: pipeline, environment: "foo-#{project.default_branch}")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when referenced with a variable' do
      let(:build) do
        create(:ci_build, pipeline: pipeline, environment: "foo-$CI_COMMIT_REF_NAME")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when there is no environment' do
      it { is_expected.to be_nil }
    end

    context 'when build has a start environment' do
      let(:build) { create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline) }

      it 'does not expand environment name' do
        expect(build).not_to receive(:expanded_environment_name)

        subject
      end
    end

    context 'when build has a stop environment' do
      let(:build) { create(:ci_build, :stop_review_app, pipeline: pipeline) }

      it 'expands environment name' do
        expect(build).to receive(:expanded_environment_name)

        subject
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
        subject { build_stubbed(:ci_build, :manual, status: :skipped) }

        it { is_expected.not_to be_playable }
      end

      context 'when build has been canceled' do
        subject { build_stubbed(:ci_build, :manual, status: :canceled) }

        it { is_expected.to be_playable }
      end

      context 'when build is successful' do
        subject { build_stubbed(:ci_build, :manual, status: :success) }

        it { is_expected.to be_playable }
      end

      context 'when build has failed' do
        subject { build_stubbed(:ci_build, :manual, status: :failed) }

        it { is_expected.to be_playable }
      end

      context 'when build is a manual untriggered action' do
        subject { build_stubbed(:ci_build, :manual, status: :manual) }

        it { is_expected.to be_playable }
      end

      context 'when build is a manual and degenerated' do
        subject { build_stubbed(:ci_build, :manual, :degenerated, status: :manual) }

        it { is_expected.not_to be_playable }
      end
    end

    context 'when build is scheduled' do
      subject { build_stubbed(:ci_build, :scheduled) }

      it { is_expected.to be_playable }
    end

    context 'when build is not a manual action' do
      subject { build_stubbed(:ci_build, :success) }

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
    {
      'master'                => 'master',
      '1-foo'                 => '1-foo',
      'fix/1-foo'             => 'fix-1-foo',
      'fix-1-foo'             => 'fix-1-foo',
      'a' * 63                => 'a' * 63,
      'a' * 64                => 'a' * 63,
      'FOO'                   => 'foo',
      '-' + 'a' * 61 + '-'    => 'a' * 61,
      '-' + 'a' * 62 + '-'    => 'a' * 62,
      '-' + 'a' * 63 + '-'    => 'a' * 62,
      'a' * 62 + ' '          => 'a' * 62
    }.each do |ref, slug|
      it "transforms #{ref} to #{slug}" do
        build.ref = ref

        expect(build.ref_slug).to eq(slug)
      end
    end
  end

  describe '#repo_url' do
    subject { build.repo_url }

    context 'when token is set' do
      before do
        build.ensure_token
      end

      it { is_expected.to be_a(String) }
      it { is_expected.to end_with(".git") }
      it { is_expected.to start_with(project.web_url[0..6]) }
      it { is_expected.to include(build.token) }
      it { is_expected.to include('gitlab-ci-token') }
      it { is_expected.to include(project.web_url[7..-1]) }
    end

    context 'when token is empty' do
      before do
        build.update_columns(token: nil, token_encrypted: nil)
      end

      it { is_expected.to be_nil}
    end
  end

  describe '#stuck?' do
    subject { build.stuck? }

    context "when commit_status.status is pending" do
      before do
        build.status = 'pending'
      end

      it { is_expected.to be_truthy }

      context "and there are specific runner" do
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

  describe '#has_expiring_artifacts?' do
    context 'when artifacts have expiration date set' do
      before do
        build.update(artifacts_expire_at: 1.day.from_now)
      end

      it 'has expiring artifacts' do
        expect(build).to have_expiring_artifacts
      end
    end

    context 'when artifacts do not have expiration date set' do
      before do
        build.update(artifacts_expire_at: nil)
      end

      it 'does not have expiring artifacts' do
        expect(build).not_to have_expiring_artifacts
      end
    end
  end

  describe '#variables' do
    let(:container_registry_enabled) { false }

    before do
      stub_container_registry_config(enabled: container_registry_enabled, host_port: 'registry.example.com')
    end

    subject { build.variables }

    context 'returns variables' do
      let(:predefined_variables) do
        [
          { key: 'CI_PIPELINE_ID', value: pipeline.id.to_s, public: true, masked: false },
          { key: 'CI_PIPELINE_URL', value: project.web_url + "/pipelines/#{pipeline.id}", public: true, masked: false },
          { key: 'CI_JOB_ID', value: build.id.to_s, public: true, masked: false },
          { key: 'CI_JOB_URL', value: project.web_url + "/-/jobs/#{build.id}", public: true, masked: false },
          { key: 'CI_JOB_TOKEN', value: 'my-token', public: false, masked: true },
          { key: 'CI_BUILD_ID', value: build.id.to_s, public: true, masked: false },
          { key: 'CI_BUILD_TOKEN', value: 'my-token', public: false, masked: true },
          { key: 'CI_REGISTRY_USER', value: 'gitlab-ci-token', public: true, masked: false },
          { key: 'CI_REGISTRY_PASSWORD', value: 'my-token', public: false, masked: true },
          { key: 'CI_REPOSITORY_URL', value: build.repo_url, public: false, masked: false },
          { key: 'CI_JOB_NAME', value: 'test', public: true, masked: false },
          { key: 'CI_JOB_STAGE', value: 'test', public: true, masked: false },
          { key: 'CI_NODE_TOTAL', value: '1', public: true, masked: false },
          { key: 'CI_BUILD_NAME', value: 'test', public: true, masked: false },
          { key: 'CI_BUILD_STAGE', value: 'test', public: true, masked: false },
          { key: 'CI', value: 'true', public: true, masked: false },
          { key: 'GITLAB_CI', value: 'true', public: true, masked: false },
          { key: 'CI_SERVER_HOST', value: Gitlab.config.gitlab.host, public: true, masked: false },
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
          { key: 'CI_PROJECT_PATH', value: project.full_path, public: true, masked: false },
          { key: 'CI_PROJECT_PATH_SLUG', value: project.full_path_slug, public: true, masked: false },
          { key: 'CI_PROJECT_NAMESPACE', value: project.namespace.full_path, public: true, masked: false },
          { key: 'CI_PROJECT_URL', value: project.web_url, public: true, masked: false },
          { key: 'CI_PROJECT_VISIBILITY', value: 'private', public: true, masked: false },
          { key: 'CI_PROJECT_REPOSITORY_LANGUAGES', value: project.repository_languages.map(&:name).join(',').downcase, public: true, masked: false },
          { key: 'CI_DEFAULT_BRANCH', value: project.default_branch, public: true, masked: false },
          { key: 'CI_PAGES_DOMAIN', value: Gitlab.config.pages.host, public: true, masked: false },
          { key: 'CI_PAGES_URL', value: project.pages_url, public: true, masked: false },
          { key: 'CI_API_V4_URL', value: 'http://localhost/api/v4', public: true, masked: false },
          { key: 'CI_PIPELINE_IID', value: pipeline.iid.to_s, public: true, masked: false },
          { key: 'CI_PIPELINE_SOURCE', value: pipeline.source, public: true, masked: false },
          { key: 'CI_CONFIG_PATH', value: pipeline.config_path, public: true, masked: false },
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
          { key: 'CI_BUILD_REF', value: build.sha, public: true, masked: false },
          { key: 'CI_BUILD_BEFORE_SHA', value: build.before_sha, public: true, masked: false },
          { key: 'CI_BUILD_REF_NAME', value: build.ref, public: true, masked: false },
          { key: 'CI_BUILD_REF_SLUG', value: build.ref_slug, public: true, masked: false }
        ]
      end

      before do
        build.set_token('my-token')
        build.yaml_variables = []
      end

      it { is_expected.to eq(predefined_variables) }

      describe 'variables ordering' do
        context 'when variables hierarchy is stubbed' do
          let(:build_pre_var) { { key: 'build', value: 'value', public: true, masked: false } }
          let(:project_pre_var) { { key: 'project', value: 'value', public: true, masked: false } }
          let(:pipeline_pre_var) { { key: 'pipeline', value: 'value', public: true, masked: false } }
          let(:build_yaml_var) { { key: 'yaml', value: 'value', public: true, masked: false } }

          before do
            allow(build).to receive(:predefined_variables) { [build_pre_var] }
            allow(build).to receive(:yaml_variables) { [build_yaml_var] }
            allow(build).to receive(:persisted_variables) { [] }

            allow_any_instance_of(Project)
              .to receive(:predefined_variables) { [project_pre_var] }

            project.variables.create!(key: 'secret', value: 'value')

            allow_any_instance_of(Ci::Pipeline)
              .to receive(:predefined_variables) { [pipeline_pre_var] }
          end

          it 'returns variables in order depending on resource hierarchy' do
            is_expected.to eq(
              [build_pre_var,
               project_pre_var,
               pipeline_pre_var,
               build_yaml_var,
               { key: 'secret', value: 'value', public: false, masked: false }])
          end
        end

        context 'when build has environment and user-provided variables' do
          let(:expected_variables) do
            predefined_variables.map { |variable| variable.fetch(:key) } +
              %w[YAML_VARIABLE CI_ENVIRONMENT_NAME CI_ENVIRONMENT_SLUG
                 CI_ENVIRONMENT_URL]
          end

          before do
            create(:environment, project: build.project,
                                 name: 'staging')

            build.yaml_variables = [{ key: 'YAML_VARIABLE',
                                      value: 'var',
                                      public: true }]
            build.environment = 'staging'
          end

          it 'matches explicit variables ordering' do
            received_variables = subject.map { |variable| variable.fetch(:key) }

            expect(received_variables).to eq expected_variables
          end
        end
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
        build.update(user: user)
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
      let(:environment_variables) do
        [
          { key: 'CI_ENVIRONMENT_NAME', value: 'production', public: true, masked: false },
          { key: 'CI_ENVIRONMENT_SLUG', value: 'prod-slug',  public: true, masked: false }
        ]
      end

      let!(:environment) do
        create(:environment,
               project: build.project,
               name: 'production',
               slug: 'prod-slug',
               external_url: '')
      end

      before do
        build.update(environment: 'production')
      end

      shared_examples 'containing environment variables' do
        it { environment_variables.each { |v| is_expected.to include(v) } }
      end

      context 'when no URL was set' do
        it_behaves_like 'containing environment variables'

        it 'does not have CI_ENVIRONMENT_URL' do
          keys = subject.map { |var| var[:key] }

          expect(keys).not_to include('CI_ENVIRONMENT_URL')
        end
      end

      context 'when an URL was set' do
        let(:url) { 'http://host/test' }

        before do
          environment_variables <<
            { key: 'CI_ENVIRONMENT_URL', value: url, public: true, masked: false }
        end

        context 'when the URL was set from the job' do
          before do
            build.update(options: { environment: { url: url } })
          end

          it_behaves_like 'containing environment variables'

          context 'when variables are used in the URL, it does not expand' do
            let(:url) { 'http://$CI_PROJECT_NAME-$CI_ENVIRONMENT_SLUG' }

            it_behaves_like 'containing environment variables'

            it 'puts $CI_ENVIRONMENT_URL in the last so all other variables are available to be used when runners are trying to expand it' do
              expect(subject.last).to eq(environment_variables.last)
            end
          end
        end

        context 'when the URL was not set from the job, but environment' do
          before do
            environment.update(external_url: url)
          end

          it_behaves_like 'containing environment variables'
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
          before do
            create(:environment, name: 'staging', project: project)
            build.update!(environment: 'staging')
          end

          it { is_expected.to include(environment_specific_variable) }
        end
      end
    end

    context 'when build started manually' do
      before do
        build.update(when: :manual)
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
        build.update(tag: false)
        pipeline.update(tag: false)
      end

      it { is_expected.to include(branch_variable) }
    end

    context 'when build is for tag' do
      let(:tag_variable) do
        { key: 'CI_COMMIT_TAG', value: 'master', public: true, masked: false }
      end

      before do
        build.update(tag: true)
        pipeline.update(tag: true)
      end

      it { is_expected.to include(tag_variable) }
    end

    context 'when CI variable is defined' do
      let(:ci_variable) do
        { key: 'SECRET_KEY', value: 'secret_value', public: false, masked: false }
      end

      before do
        create(:ci_variable,
               ci_variable.slice(:key, :value).merge(project: project))
      end

      it { is_expected.to include(ci_variable) }
    end

    context 'when protected variable is defined' do
      let(:ref) { Gitlab::Git::BRANCH_REF_PREFIX + build.ref }

      let(:protected_variable) do
        { key: 'PROTECTED_KEY', value: 'protected_value', public: false, masked: false }
      end

      before do
        create(:ci_variable,
               :protected,
               protected_variable.slice(:key, :value).merge(project: project))
      end

      context 'when the branch is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the tag is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(ref).and_return(true)
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
        create(:ci_group_variable,
               ci_variable.slice(:key, :value).merge(group: group))
      end

      it { is_expected.to include(ci_variable) }
    end

    context 'when group protected variable is defined' do
      let(:ref) { Gitlab::Git::BRANCH_REF_PREFIX + build.ref }

      let(:protected_variable) do
        { key: 'PROTECTED_KEY', value: 'protected_value', public: false, masked: false }
      end

      before do
        create(:ci_group_variable,
               :protected,
               protected_variable.slice(:key, :value).merge(group: group))
      end

      context 'when the branch is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(ref).and_return(true)
        end

        it { is_expected.to include(protected_variable) }
      end

      context 'when the tag is protected' do
        before do
          allow(build.project).to receive(:protected_for?).with(ref).and_return(true)
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

    context 'when build is for triggers' do
      let(:trigger) { create(:ci_trigger, project: project) }
      let(:trigger_request) { create(:ci_trigger_request, pipeline: pipeline, trigger: trigger) }

      let(:user_trigger_variable) do
        { key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1', public: false, masked: false }
      end

      let(:predefined_trigger_variable) do
        { key: 'CI_PIPELINE_TRIGGERED', value: 'true', public: true, masked: false }
      end

      before do
        build.trigger_request = trigger_request
      end

      shared_examples 'returns variables for triggers' do
        it { is_expected.to include(user_trigger_variable) }
        it { is_expected.to include(predefined_trigger_variable) }
      end

      context 'when variables are stored in trigger_request' do
        before do
          trigger_request.update_attribute(:variables, { 'TRIGGER_KEY_1' => 'TRIGGER_VALUE_1' } )
        end

        it_behaves_like 'returns variables for triggers'
      end

      context 'when variables are stored in pipeline_variables' do
        before do
          create(:ci_pipeline_variable, pipeline: pipeline, key: 'TRIGGER_KEY_1', value: 'TRIGGER_VALUE_1')
        end

        it_behaves_like 'returns variables for triggers'
      end
    end

    context 'when pipeline has a variable' do
      let!(:pipeline_variable) { create(:ci_pipeline_variable, pipeline: pipeline) }

      it { is_expected.to include(key: pipeline_variable.key, value: pipeline_variable.value, public: false, masked: false) }
    end

    context 'when a job was triggered by a pipeline schedule' do
      let(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }

      let!(:pipeline_schedule_variable) do
        create(:ci_pipeline_schedule_variable,
               key: 'SCHEDULE_VARIABLE_KEY',
               pipeline_schedule: pipeline_schedule)
      end

      before do
        pipeline_schedule.pipelines << pipeline.reload
        pipeline_schedule.reload
      end

      it { is_expected.to include(key: pipeline_schedule_variable.key, value: pipeline_schedule_variable.value, public: false, masked: false) }
    end

    context 'when container registry is enabled' do
      let(:container_registry_enabled) { true }
      let(:ci_registry) do
        { key: 'CI_REGISTRY', value: 'registry.example.com', public: true, masked: false }
      end
      let(:ci_registry_image) do
        { key: 'CI_REGISTRY_IMAGE', value: project.container_registry_url, public: true, masked: false }
      end

      context 'and is disabled for project' do
        before do
          project.update(container_registry_enabled: false)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.not_to include(ci_registry_image) }
      end

      context 'and is enabled for project' do
        before do
          project.update(container_registry_enabled: true)
        end

        it { is_expected.to include(ci_registry) }
        it { is_expected.to include(ci_registry_image) }
      end
    end

    context 'when runner is assigned to build' do
      let(:runner) { create(:ci_runner, description: 'description', tag_list: %w(docker linux)) }

      before do
        build.update(runner: runner)
      end

      it { is_expected.to include({ key: 'CI_RUNNER_ID', value: runner.id.to_s, public: true, masked: false }) }
      it { is_expected.to include({ key: 'CI_RUNNER_DESCRIPTION', value: 'description', public: true, masked: false }) }
      it { is_expected.to include({ key: 'CI_RUNNER_TAGS', value: 'docker, linux', public: true, masked: false }) }
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
        expect_any_instance_of(Project).to receive(:ci_config_path) { 'custom' }
      end

      it { is_expected.to include(ci_config_path) }
    end

    context 'when pipeline variable overrides build variable' do
      before do
        build.yaml_variables = [{ key: 'MYVAR', value: 'myvar', public: true }]
        pipeline.variables.build(key: 'MYVAR', value: 'pipeline value')
      end

      it 'overrides YAML variable using a pipeline variable' do
        variables = subject.reverse.uniq { |variable| variable[:key] }.reverse

        expect(variables)
          .not_to include(key: 'MYVAR', value: 'myvar', public: true, masked: false)
        expect(variables)
          .to include(key: 'MYVAR', value: 'pipeline value', public: false, masked: false)
      end
    end

    context 'when build is parallelized' do
      let(:total) { 5 }
      let(:index) { 3 }

      before do
        build.options[:parallel] = total
        build.options[:instance] = index
        build.name = "#{build.name} #{index}/#{total}"
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

    context 'when build has not been persisted yet' do
      let(:build) do
        described_class.new(
          name: 'rspec',
          stage: 'test',
          ref: 'feature',
          project: project,
          pipeline: pipeline
        )
      end

      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'feature') }

      it 'returns static predefined variables' do
        expect(build.variables.size).to be >= 28
        expect(build.variables)
          .to include(key: 'CI_COMMIT_REF_NAME', value: 'feature', public: true, masked: false)
        expect(build).not_to be_persisted
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

      context 'when gitlab-deploy-token exists' do
        before do
          project.deploy_tokens << deploy_token
        end

        it 'includes deploy token variables' do
          is_expected.to include(*deploy_token_variables)
        end
      end

      context 'when gitlab-deploy-token does not exist' do
        it 'does not include deploy token variables' do
          expect(subject.find { |v| v[:key] == 'CI_DEPLOY_USER'}).to be_nil
          expect(subject.find { |v| v[:key] == 'CI_DEPLOY_PASSWORD'}).to be_nil
        end
      end
    end
  end

  describe '#scoped_variables' do
    context 'when build has not been persisted yet' do
      let(:build) do
        described_class.new(
          name: 'rspec',
          stage: 'test',
          ref: 'feature',
          project: project,
          pipeline: pipeline
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
                  CI_BUILD_ID
                  CI_BUILD_TOKEN
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
  end

  describe '#secret_group_variables' do
    subject { build.secret_group_variables }

    let!(:variable) { create(:ci_group_variable, protected: true, group: group) }

    context 'when ref is branch' do
      let(:build) { create(:ci_build, ref: 'master', tag: false, project: project) }

      context 'when ref is protected' do
        before do
          create(:protected_branch, :developers_can_merge, name: 'master', project: project)
        end

        it { is_expected.to include(variable) }
      end

      context 'when ref is not protected' do
        it { is_expected.not_to include(variable) }
      end
    end

    context 'when ref is tag' do
      let(:build) { create(:ci_build, ref: 'v1.1.0', tag: true, project: project) }

      context 'when ref is protected' do
        before do
          create(:protected_tag, project: project, name: 'v*')
        end

        it { is_expected.to include(variable) }
      end

      context 'when ref is not protected' do
        it { is_expected.not_to include(variable) }
      end
    end

    context 'when ref is merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.pipelines_for_merge_request.first }
      let(:build) { create(:ci_build, ref: merge_request.source_branch, tag: false, pipeline: pipeline, project: project) }

      context 'when ref is protected' do
        before do
          create(:protected_branch, :developers_can_merge, name: merge_request.source_branch, project: project)
        end

        it 'does not return protected variables as it is not supported for merge request pipelines' do
          is_expected.not_to include(variable)
        end
      end

      context 'when ref is not protected' do
        it { is_expected.not_to include(variable) }
      end
    end
  end

  describe '#secret_project_variables' do
    subject { build.secret_project_variables }

    let!(:variable) { create(:ci_variable, protected: true, project: project) }

    context 'when ref is branch' do
      let(:build) { create(:ci_build, ref: 'master', tag: false, project: project) }

      context 'when ref is protected' do
        before do
          create(:protected_branch, :developers_can_merge, name: 'master', project: project)
        end

        it { is_expected.to include(variable) }
      end

      context 'when ref is not protected' do
        it { is_expected.not_to include(variable) }
      end
    end

    context 'when ref is tag' do
      let(:build) { create(:ci_build, ref: 'v1.1.0', tag: true, project: project) }

      context 'when ref is protected' do
        before do
          create(:protected_tag, project: project, name: 'v*')
        end

        it { is_expected.to include(variable) }
      end

      context 'when ref is not protected' do
        it { is_expected.not_to include(variable) }
      end
    end

    context 'when ref is merge request' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }
      let(:pipeline) { merge_request.pipelines_for_merge_request.first }
      let(:build) { create(:ci_build, ref: merge_request.source_branch, tag: false, pipeline: pipeline, project: project) }

      context 'when ref is protected' do
        before do
          create(:protected_branch, :developers_can_merge, name: merge_request.source_branch, project: project)
        end

        it 'does not return protected variables as it is not supported for merge request pipelines' do
          is_expected.not_to include(variable)
        end
      end

      context 'when ref is not protected' do
        it { is_expected.not_to include(variable) }
      end
    end
  end

  describe '#deployment_variables' do
    let(:build) { create(:ci_build, environment: environment) }
    let(:environment) { 'production' }
    let(:kubernetes_namespace) { 'namespace' }
    let(:project_variables) { double }

    subject { build.deployment_variables(environment: environment) }

    before do
      allow(build).to receive(:expanded_kubernetes_namespace)
        .and_return(kubernetes_namespace)

      allow(build.project).to receive(:deployment_variables)
        .with(environment: environment, kubernetes_namespace: kubernetes_namespace)
        .and_return(project_variables)
    end

    it { is_expected.to eq(project_variables) }

    context 'environment is nil' do
      let(:environment) { nil }

      it { is_expected.to be_empty }
    end
  end

  describe '#scoped_variables_hash' do
    context 'when overriding CI variables' do
      before do
        project.variables.create!(key: 'MY_VAR', value: 'my value 1')
        pipeline.variables.create!(key: 'MY_VAR', value: 'my value 2')
      end

      it 'returns a regular hash created using valid ordering' do
        expect(build.scoped_variables_hash).to include('MY_VAR': 'my value 2')
        expect(build.scoped_variables_hash).not_to include('MY_VAR': 'my value 1')
      end
    end

    context 'when overriding user-provided variables' do
      before do
        pipeline.variables.build(key: 'MY_VAR', value: 'pipeline value')
        build.yaml_variables = [{ key: 'MY_VAR', value: 'myvar', public: true }]
      end

      it 'returns a hash including variable with higher precedence' do
        expect(build.scoped_variables_hash).to include('MY_VAR': 'pipeline value')
        expect(build.scoped_variables_hash).not_to include('MY_VAR': 'myvar')
      end
    end
  end

  describe '#any_unmet_prerequisites?' do
    let(:build) { create(:ci_build, :created) }

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

    context 'when ci_build_metadata_config is set' do
      before do
        stub_feature_flags(ci_build_metadata_config: true)
      end

      it_behaves_like 'having consistent representation'

      it 'persist data in build metadata' do
        expect(build.metadata.read_attribute(:config_variables)).not_to be_nil
      end

      it 'does not persist data in build' do
        expect(build.read_attribute(:yaml_variables)).to be_nil
      end
    end

    context 'when ci_build_metadata_config is disabled' do
      before do
        stub_feature_flags(ci_build_metadata_config: false)
      end

      it_behaves_like 'having consistent representation'

      it 'persist data in build' do
        expect(build.read_attribute(:yaml_variables)).not_to be_nil
      end

      it 'does not persist data in build metadata' do
        expect(build.metadata.read_attribute(:config_variables)).to be_nil
      end
    end
  end

  describe 'state transition: any => [:preparing]' do
    let(:build) { create(:ci_build, :created) }

    before do
      allow(build).to receive(:prerequisites).and_return([double])
    end

    it 'queues BuildPrepareWorker' do
      expect(Ci::BuildPrepareWorker).to receive(:perform_async).with(build.id)

      build.enqueue
    end
  end

  describe 'state transition: any => [:pending]' do
    let(:build) { create(:ci_build, :created) }

    it 'queues BuildQueueWorker' do
      expect(BuildQueueWorker).to receive(:perform_async).with(build.id)

      build.enqueue
    end
  end

  describe 'state transition: pending: :running' do
    let(:runner) { create(:ci_runner) }
    let(:job) { create(:ci_build, :pending, runner: runner) }

    before do
      job.project.update_attribute(:build_timeout, 1800)
    end

    def run_job_without_exception
      job.run!
    rescue StateMachines::InvalidTransition
    end

    context 'for pipeline ref existence' do
      it 'ensures pipeline ref creation' do
        expect(job.pipeline.persistent_ref).to receive(:create).once

        run_job_without_exception
      end

      it 'ensures that it is not run in database transaction' do
        expect(job.pipeline.persistent_ref).to receive(:create) do
          expect(Gitlab::Database).not_to be_inside_transaction
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
          expect { run_job_without_exception }.not_to change { job.reload.ensure_metadata.timeout_source }
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

        it { expect(job).not_to have_valid_build_dependencies }
      end

      context 'when artifacts of depended job has been erased' do
        let!(:pre_stage_job) { create(:ci_build, :success, pipeline: pipeline, name: 'test', stage_idx: 0, erased_at: 1.minute.ago) }

        before do
          pre_stage_job.erase
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

        before do
          pre_stage_job.erase
        end

        it { expect(job).to have_valid_build_dependencies }
      end
    end

    let!(:job) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 1, options: options) }

    context 'when validates for dependencies is enabled' do
      before do
        stub_feature_flags(ci_disable_validates_dependencies: false)
      end

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

    context 'when validates for dependencies is disabled' do
      let(:options) { { dependencies: ['test'] } }

      before do
        stub_feature_flags(ci_disable_validates_dependencies: true)
      end

      it_behaves_like 'validation is not active'
    end
  end

  describe 'state transition when build fails' do
    let(:service) { MergeRequests::AddTodoWhenBuildFailsService.new(project, user) }

    before do
      allow(MergeRequests::AddTodoWhenBuildFailsService).to receive(:new).and_return(service)
      allow(service).to receive(:close)
    end

    context 'when build is configured to be retried' do
      subject { create(:ci_build, :running, options: { script: ["ls -al"], retry: 3 }, project: project, user: user) }

      it 'retries build and assigns the same user to it' do
        expect(described_class).to receive(:retry)
          .with(subject, user)

        subject.drop!
      end

      it 'does not try to create a todo' do
        project.add_developer(user)

        expect(service).not_to receive(:pipeline_merge_requests)

        subject.drop!
      end

      context 'when retry service raises Gitlab::Access::AccessDeniedError exception' do
        let(:retry_service) { Ci::RetryBuildService.new(subject.project, subject.user) }

        before do
          allow_any_instance_of(Ci::RetryBuildService)
            .to receive(:execute)
            .with(subject)
            .and_raise(Gitlab::Access::AccessDeniedError)
          allow(Rails.logger).to receive(:error)
        end

        it 'handles raised exception' do
          expect { subject.drop! }.not_to raise_exception(Gitlab::Access::AccessDeniedError)
        end

        it 'logs the error' do
          subject.drop!

          expect(Rails.logger)
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
      subject { create(:ci_build, :running, project: project, user: user, pipeline: pipeline) }

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

      it 'creates a todo' do
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
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

        expect { build.drop! }.not_to raise_error

        expect(build).to be_failed
      end
    end
  end

  describe '.matches_tag_ids' do
    set(:build) { create(:ci_build, project: project, user: user) }
    let(:tag_ids) { ::ActsAsTaggableOn::Tag.named_any(tag_list).ids }

    subject { described_class.where(id: build).matches_tag_ids(tag_ids) }

    before do
      build.update(tag_list: build_tag_list)
    end

    context 'when have different tags' do
      let(:build_tag_list) { %w(A B) }
      let(:tag_list) { %w(C D) }

      it "does not match a build" do
        is_expected.not_to contain_exactly(build)
      end
    end

    context 'when have a subset of tags' do
      let(:build_tag_list) { %w(A B) }
      let(:tag_list) { %w(A B C D) }

      it "does match a build" do
        is_expected.to contain_exactly(build)
      end
    end

    context 'when build does not have tags' do
      let(:build_tag_list) { [] }
      let(:tag_list) { %w(C D) }

      it "does match a build" do
        is_expected.to contain_exactly(build)
      end
    end

    context 'when does not have a subset of tags' do
      let(:build_tag_list) { %w(A B C) }
      let(:tag_list) { %w(C D) }

      it "does not match a build" do
        is_expected.not_to contain_exactly(build)
      end
    end
  end

  describe '.matches_tags' do
    set(:build) { create(:ci_build, project: project, user: user) }

    subject { described_class.where(id: build).with_any_tags }

    before do
      build.update(tag_list: tag_list)
    end

    context 'when does have tags' do
      let(:tag_list) { %w(A B) }

      it "does match a build" do
        is_expected.to contain_exactly(build)
      end
    end

    context 'when does not have tags' do
      let(:tag_list) { [] }

      it "does not match a build" do
        is_expected.not_to contain_exactly(build)
      end
    end
  end

  describe 'pages deployments' do
    set(:build) { create(:ci_build, project: project, user: user) }

    context 'when job is "pages"' do
      before do
        build.name = 'pages'
      end

      context 'when pages are enabled' do
        before do
          allow(Gitlab.config.pages).to receive_messages(enabled: true)
        end

        it 'is marked as pages generator' do
          expect(build).to be_pages_generator
        end

        context 'job succeeds' do
          it "calls pages worker" do
            expect(PagesWorker).to receive(:perform_async).with(:deploy, build.id)

            build.success!
          end
        end

        context 'job fails' do
          it "does not call pages worker" do
            expect(PagesWorker).not_to receive(:perform_async)

            build.drop!
          end
        end
      end

      context 'when pages are disabled' do
        before do
          allow(Gitlab.config.pages).to receive_messages(enabled: false)
        end

        it 'is not marked as pages generator' do
          expect(build).not_to be_pages_generator
        end

        context 'job succeeds' do
          it "does not call pages worker" do
            expect(PagesWorker).not_to receive(:perform_async)

            build.success!
          end
        end
      end
    end

    context 'when job is not "pages"' do
      before do
        build.name = 'other-job'
      end

      it 'is not marked as pages generator' do
        expect(build).not_to be_pages_generator
      end

      context 'job succeeds' do
        it "does not call pages worker" do
          expect(PagesWorker).not_to receive(:perform_async)

          build.success
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
    subject { build.collect_test_reports!(test_reports) }

    let(:test_reports) { Gitlab::Ci::Reports::TestReports.new }

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

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Ci::Parsers::Test::Junit::JunitParserError)
        end
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
    set(:build) { create(:ci_build, project: project) }
    let(:path) { 'other_artifacts_0.1.2/another-subdirectory/banana_sample.gif' }

    before do
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
    let(:build) { create(:ci_build, options: options) }

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
    let(:build) { create(:ci_build, options: options) }

    subject { build.runner_required_feature_names }

    context 'when artifacts reports are defined' do
      let(:options) do
        { artifacts: { reports: { junit: "junit.xml" } } }
      end

      it { is_expected.to include(:upload_multiple_artifacts) }
    end
  end

  describe '#supported_runner?' do
    set(:build) { create(:ci_build) }

    subject { build.supported_runner?(runner_features) }

    context 'when feature is required by build' do
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

    context 'when refspecs feature is required by build' do
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
  end

  describe '#deployment_status' do
    before do
      allow_any_instance_of(described_class).to receive(:create_deployment)
    end

    context 'when build is a last deployment' do
      let(:build) { create(:ci_build, :success, environment: 'production') }
      let(:environment) { create(:environment, name: 'production', project: build.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: build) }

      it { expect(build.deployment_status).to eq(:last) }
    end

    context 'when there is a newer build with deployment' do
      let(:build) { create(:ci_build, :success, environment: 'production') }
      let(:environment) { create(:environment, name: 'production', project: build.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: build) }
      let!(:last_deployment) { create(:deployment, :success, environment: environment, project: environment.project) }

      it { expect(build.deployment_status).to eq(:out_of_date) }
    end

    context 'when build with deployment has failed' do
      let(:build) { create(:ci_build, :failed, environment: 'production') }
      let(:environment) { create(:environment, name: 'production', project: build.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: build) }

      it { expect(build.deployment_status).to eq(:failed) }
    end

    context 'when build with deployment is running' do
      let(:build) { create(:ci_build, environment: 'production') }
      let(:environment) { create(:environment, name: 'production', project: build.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: build) }

      it { expect(build.deployment_status).to eq(:creating) }
    end
  end

  describe '#degenerated?' do
    context 'when build is degenerated' do
      subject { create(:ci_build, :degenerated) }

      it { is_expected.to be_degenerated }
    end

    context 'when build is valid' do
      subject { create(:ci_build) }

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
    let(:build) { create(:ci_build) }

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
      subject { create(:ci_build, :degenerated) }

      it { is_expected.to be_archived }
    end

    context 'for old build' do
      subject { create(:ci_build, created_at: 1.day.ago) }

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
    let(:build) { create(:ci_build, :degenerated) }
    let(:build_options) { { "key" => "build" } }
    let(:metadata_options) { { "key" => "metadata" } }
    let(:default_options) { { "key" => "default" } }

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
    let(:build) { create(:ci_build, :degenerated) }
    let(:options) { { "key" => "new options" } }
    let(:existing_options) { { "key" => "existing options" } }

    subject { build.send(:write_metadata_attribute, :options, :config_options, options) }

    context 'when ci_build_metadata_config is set' do
      before do
        stub_feature_flags(ci_build_metadata_config: true)
      end

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

    context 'when ci_build_metadata_config is disabled' do
      before do
        stub_feature_flags(ci_build_metadata_config: false)
      end

      context 'when data in build metadata is already set' do
        before do
          build.ensure_metadata.write_attribute(:config_options, existing_options)
        end

        it 'does set metadata options' do
          subject

          expect(build.read_attribute(:options)).to eq(options)
        end

        it 'does reset build options' do
          subject

          expect(build.metadata.read_attribute(:config_options)).to be_nil
        end
      end
    end
  end

  describe '#invalid_dependencies' do
    let!(:pre_stage_job_valid) { create(:ci_build, :manual, pipeline: pipeline, name: 'test1', stage_idx: 0) }
    let!(:pre_stage_job_invalid) { create(:ci_build, :success, :expired, pipeline: pipeline, name: 'test2', stage_idx: 1) }
    let!(:job) { create(:ci_build, :pending, pipeline: pipeline, stage_idx: 2, options: { dependencies: %w(test1 test2) }) }

    it 'returns invalid dependencies' do
      expect(job.invalid_dependencies).to eq([pre_stage_job_invalid])
    end
  end

  describe '#execute_hooks' do
    context 'with project hooks' do
      before do
        create(:project_hook, project: project, job_events: true)
      end

      it 'execute hooks' do
        expect_any_instance_of(ProjectHook).to receive(:async_execute)

        build.execute_hooks
      end
    end

    context 'without relevant project hooks' do
      before do
        create(:project_hook, project: project, job_events: false)
      end

      it 'does not execute a hook' do
        expect_any_instance_of(ProjectHook).not_to receive(:async_execute)

        build.execute_hooks
      end
    end

    context 'with project services' do
      before do
        create(:service, active: true, job_events: true, project: project)
      end

      it 'execute services' do
        expect_any_instance_of(Service).to receive(:async_execute)

        build.execute_hooks
      end
    end

    context 'without relevant project services' do
      before do
        create(:service, active: true, job_events: false, project: project)
      end

      it 'execute services' do
        expect_any_instance_of(Service).not_to receive(:async_execute)

        build.execute_hooks
      end
    end
  end

  describe '#environment_auto_stop_in' do
    subject { build.environment_auto_stop_in }

    context 'when build option has environment auto_stop_in' do
      let(:build) { create(:ci_build, options: { environment: { name: 'test', auto_stop_in: '1 day' } }) }

      it { is_expected.to eq('1 day') }
    end

    context 'when build option does not have environment auto_stop_in' do
      let(:build) { create(:ci_build) }

      it { is_expected.to be_nil }
    end
  end
end
