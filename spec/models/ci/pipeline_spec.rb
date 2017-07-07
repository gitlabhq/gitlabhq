require 'spec_helper'

describe Ci::Pipeline, models: true do
  include EmailHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:auto_canceled_by) }
  it { is_expected.to belong_to(:pipeline_schedule) }

  it { is_expected.to have_many(:statuses) }
  it { is_expected.to have_many(:trigger_requests) }
  it { is_expected.to have_many(:builds) }
  it { is_expected.to have_many(:auto_canceled_pipelines) }
  it { is_expected.to have_many(:auto_canceled_jobs) }
  it { is_expected.to have_one(:source_pipeline) }
  it { is_expected.to have_many(:sourced_pipelines) }
  it { is_expected.to have_one(:triggered_by_pipeline) }
  it { is_expected.to have_many(:triggered_pipelines) }

  it { is_expected.to validate_presence_of(:sha) }
  it { is_expected.to validate_presence_of(:status) }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :short_sha }

  describe '#source' do
    context 'when creating new pipeline' do
      let(:pipeline) do
        build(:ci_empty_pipeline, status: :created, project: project, source: nil)
      end

      it "prevents from creating an object" do
        expect(pipeline).not_to be_valid
      end
    end

    context 'when updating existing pipeline' do
      before do
        pipeline.update_attribute(:source, nil)
      end

      it "object is valid" do
        expect(pipeline).to be_valid
      end
    end
  end

  describe '#block' do
    it 'changes pipeline status to manual' do
      expect(pipeline.block).to be true
      expect(pipeline.reload).to be_manual
      expect(pipeline.reload).to be_blocked
    end
  end

  describe '#valid_commit_sha' do
    context 'commit.sha can not start with 00000000' do
      before do
        pipeline.sha = '0' * 40
        pipeline.valid_commit_sha
      end

      it('commit errors should not be empty') { expect(pipeline.errors).not_to be_empty }
    end
  end

  describe '#short_sha' do
    subject { pipeline.short_sha }

    it 'has 8 items' do
      expect(subject.size).to eq(8)
    end
    it { expect(pipeline.sha).to start_with(subject) }
  end

  describe '#retried' do
    subject { pipeline.retried }

    before do
      @build1 = create(:ci_build, pipeline: pipeline, name: 'deploy', retried: true)
      @build2 = create(:ci_build, pipeline: pipeline, name: 'deploy')
    end

    it 'returns old builds' do
      is_expected.to contain_exactly(@build1)
    end
  end

  describe "coverage" do
    let(:project) { create(:empty_project, build_coverage_regex: "/.*/") }
    let(:pipeline) { create(:ci_empty_pipeline, project: project) }

    it "calculates average when there are two builds with coverage" do
      create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
      create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one with nil" do
      create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
      create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      create(:ci_build, pipeline: pipeline)
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one is retried" do
      create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
      create(:ci_build, name: "rubocop", coverage: 30, pipeline: pipeline, retried: true)
      create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there is one build without coverage" do
      FactoryGirl.create(:ci_build, pipeline: pipeline)
      expect(pipeline.coverage).to be_nil
    end
  end

  describe '#retryable?' do
    subject { pipeline.retryable? }

    context 'no failed builds' do
      before do
        create_build('rspec', 'success')
      end

      it 'is not retryable' do
        is_expected.to be_falsey
      end

      context 'one canceled job' do
        before do
          create_build('rubocop', 'canceled')
        end

        it 'is retryable' do
          is_expected.to be_truthy
        end
      end
    end

    context 'with failed builds' do
      before do
        create_build('rspec', 'running')
        create_build('rubocop', 'failed')
      end

      it 'is retryable' do
        is_expected.to be_truthy
      end
    end

    def create_build(name, status)
      create(:ci_build, name: name, status: status, pipeline: pipeline)
    end
  end

  describe '#auto_canceled?' do
    subject { pipeline.auto_canceled? }

    context 'when it is canceled' do
      before do
        pipeline.cancel
      end

      context 'when there is auto_canceled_by' do
        before do
          pipeline.update(auto_canceled_by: create(:ci_empty_pipeline))
        end

        it 'is auto canceled' do
          is_expected.to be_truthy
        end
      end

      context 'when there is no auto_canceled_by' do
        it 'is not auto canceled' do
          is_expected.to be_falsey
        end
      end

      context 'when it is retried and canceled manually' do
        before do
          pipeline.enqueue
          pipeline.cancel
        end

        it 'is not auto canceled' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe 'pipeline stages' do
    before do
      create(:commit_status, pipeline: pipeline,
                             stage: 'build',
                             name: 'linux',
                             stage_idx: 0,
                             status: 'success')

      create(:commit_status, pipeline: pipeline,
                             stage: 'build',
                             name: 'mac',
                             stage_idx: 0,
                             status: 'failed')

      create(:commit_status, pipeline: pipeline,
                             stage: 'deploy',
                             name: 'staging',
                             stage_idx: 2,
                             status: 'running')

      create(:commit_status, pipeline: pipeline,
                             stage: 'test',
                             name: 'rspec',
                             stage_idx: 1,
                             status: 'success')
    end

    describe '#stage_seeds' do
      let(:pipeline) do
        create(:ci_pipeline, config: { rspec: { script: 'rake' } })
      end

      it 'returns preseeded stage seeds object' do
        expect(pipeline.stage_seeds).to all(be_a Gitlab::Ci::Stage::Seed)
        expect(pipeline.stage_seeds.count).to eq 1
      end
    end

    describe '#legacy_stages' do
      subject { pipeline.legacy_stages }

      context 'stages list' do
        it 'returns ordered list of stages' do
          expect(subject.map(&:name)).to eq(%w[build test deploy])
        end
      end

      context 'stages with statuses' do
        let(:statuses) do
          subject.map { |stage| [stage.name, stage.status] }
        end

        it 'returns list of stages with correct statuses' do
          expect(statuses).to eq([%w(build failed),
                                  %w(test success),
                                  %w(deploy running)])
        end

        context 'when commit status is retried' do
          before do
            create(:commit_status, pipeline: pipeline,
                                   stage: 'build',
                                   name: 'mac',
                                   stage_idx: 0,
                                   status: 'success')

            pipeline.process!
          end

          it 'ignores the previous state' do
            expect(statuses).to eq([%w(build success),
                                    %w(test success),
                                    %w(deploy running)])
          end
        end
      end

      context 'when there is a stage with warnings' do
        before do
          create(:commit_status, pipeline: pipeline,
                                 stage: 'deploy',
                                 name: 'prod:2',
                                 stage_idx: 2,
                                 status: 'failed',
                                 allow_failure: true)
        end

        it 'populates stage with correct number of warnings' do
          deploy_stage = pipeline.legacy_stages.third

          expect(deploy_stage).not_to receive(:statuses)
          expect(deploy_stage).to have_warnings
        end
      end
    end

    describe '#stages_count' do
      it 'returns a valid number of stages' do
        expect(pipeline.stages_count).to eq(3)
      end
    end

    describe '#stages_names' do
      it 'returns a valid names of stages' do
        expect(pipeline.stages_names).to eq(%w(build test deploy))
      end
    end
  end

  describe '#legacy_stage' do
    subject { pipeline.legacy_stage('test') }

    context 'with status in stage' do
      before do
        create(:commit_status, pipeline: pipeline, stage: 'test')
      end

      it { expect(subject).to be_a Ci::LegacyStage }
      it { expect(subject.name).to eq 'test' }
      it { expect(subject.statuses).not_to be_empty }
    end

    context 'without status in stage' do
      before do
        create(:commit_status, pipeline: pipeline, stage: 'build')
      end

      it 'return stage object' do
        is_expected.to be_nil
      end
    end
  end

  describe 'state machine' do
    let(:current) { Time.now.change(usec: 0) }
    let(:build) { create_build('build1', queued_at: 0) }
    let(:build_b) { create_build('build2', queued_at: 0) }
    let(:build_c) { create_build('build3', queued_at: 0) }

    describe '#duration' do
      context 'when multiple builds are finished' do
        before do
          travel_to(current + 30) do
            build.run!
            build.success!
            build_b.run!
            build_c.run!
          end

          travel_to(current + 40) do
            build_b.drop!
          end

          travel_to(current + 70) do
            build_c.success!
          end
        end

        it 'matches sum of builds duration' do
          pipeline.reload

          expect(pipeline.duration).to eq(40)
        end
      end

      context 'when pipeline becomes blocked' do
        let!(:build) { create_build('build:1') }
        let!(:action) { create_build('manual:action', :manual) }

        before do
          travel_to(current + 1.minute) do
            build.run!
          end

          travel_to(current + 5.minutes) do
            build.success!
          end
        end

        it 'recalculates pipeline duration' do
          pipeline.reload

          expect(pipeline).to be_manual
          expect(pipeline.duration).to eq 4.minutes
        end
      end
    end

    describe '#started_at' do
      it 'updates on transitioning to running' do
        build.run

        expect(pipeline.reload.started_at).not_to be_nil
      end

      it 'does not update on transitioning to success' do
        build.success

        expect(pipeline.reload.started_at).to be_nil
      end
    end

    describe '#finished_at' do
      it 'updates on transitioning to success' do
        build.success

        expect(pipeline.reload.finished_at).not_to be_nil
      end

      it 'does not update on transitioning to running' do
        build.run

        expect(pipeline.reload.finished_at).to be_nil
      end
    end

    describe 'merge request metrics' do
      let(:project) { create(:project, :repository) }
      let(:pipeline) { FactoryGirl.create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master', sha: project.repository.commit('master').id) }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: pipeline.ref) }

      before do
        expect(PipelineMetricsWorker).to receive(:perform_async).with(pipeline.id)
      end

      context 'when transitioning to running' do
        it 'schedules metrics workers' do
          pipeline.run
        end
      end

      context 'when transitioning to success' do
        it 'schedules metrics workers' do
          pipeline.succeed
        end
      end
    end

    describe 'pipeline caching' do
      it 'performs ExpirePipelinesCacheWorker' do
        expect(ExpirePipelineCacheWorker).to receive(:perform_async).with(pipeline.id)

        pipeline.cancel
      end
    end

    def create_build(name, *traits, queued_at: current, started_from: 0, **opts)
      create(:ci_build, *traits,
             name: name,
             pipeline: pipeline,
             queued_at: queued_at,
             started_at: queued_at + started_from,
             **opts)
    end
  end

  describe '#branch?' do
    subject { pipeline.branch? }

    context 'is not a tag' do
      before do
        pipeline.tag = false
      end

      it 'return true when tag is set to false' do
        is_expected.to be_truthy
      end
    end

    context 'is not a tag' do
      before do
        pipeline.tag = true
      end

      it 'return false when tag is set to true' do
        is_expected.to be_falsey
      end
    end
  end

  context 'with non-empty project' do
    let(:project) { create(:project, :repository) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project,
             ref: project.default_branch,
             sha: project.commit.sha)
    end

    describe '#latest?' do
      context 'with latest sha' do
        it 'returns true' do
          expect(pipeline).to be_latest
        end
      end

      context 'with not latest sha' do
        before do
          pipeline.update(
            sha: project.commit("#{project.default_branch}~1").sha)
        end

        it 'returns false' do
          expect(pipeline).not_to be_latest
        end
      end
    end
  end

  describe '#manual_actions' do
    subject { pipeline.manual_actions }

    it 'when none defined' do
      is_expected.to be_empty
    end

    context 'when action defined' do
      let!(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'deploy') }

      it 'returns one action' do
        is_expected.to contain_exactly(manual)
      end

      context 'there are multiple of the same name' do
        let!(:manual2) { create(:ci_build, :manual, pipeline: pipeline, name: 'deploy') }

        before do
          manual.update(retried: true)
        end

        it 'returns latest one' do
          is_expected.to contain_exactly(manual2)
        end
      end
    end
  end

  describe '#has_stage_seeds?' do
    context 'when pipeline has stage seeds' do
      subject { build(:ci_pipeline_with_one_job) }

      it { is_expected.to have_stage_seeds }
    end

    context 'when pipeline does not have stage seeds' do
      subject { create(:ci_pipeline_without_jobs) }

      it { is_expected.not_to have_stage_seeds }
    end
  end

  describe '#has_warnings?' do
    subject { pipeline.has_warnings? }

    context 'build which is allowed to fail fails' do
      before do
        create :ci_build, :success, pipeline: pipeline, name: 'rspec'
        create :ci_build, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop'
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'build which is allowed to fail succeeds' do
      before do
        create :ci_build, :success, pipeline: pipeline, name: 'rspec'
        create :ci_build, :allowed_to_fail, :success, pipeline: pipeline, name: 'rubocop'
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'build is retried and succeeds' do
      before do
        create :ci_build, :success, pipeline: pipeline, name: 'rubocop'
        create :ci_build, :failed, pipeline: pipeline, name: 'rspec'
        create :ci_build, :success, pipeline: pipeline, name: 'rspec'
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  shared_context 'with some outdated pipelines' do
    before do
      create_pipeline(:canceled, 'ref', 'A')
      create_pipeline(:success, 'ref', 'A')
      create_pipeline(:failed, 'ref', 'B')
      create_pipeline(:skipped, 'feature', 'C')
    end

    def create_pipeline(status, ref, sha)
      create(:ci_empty_pipeline, status: status, ref: ref, sha: sha)
    end
  end

  describe '.latest' do
    include_context 'with some outdated pipelines'

    context 'when no ref is specified' do
      let(:pipelines) { described_class.latest.all }

      it 'returns the latest pipeline for the same ref and different sha' do
        expect(pipelines.map(&:sha)).to contain_exactly('A', 'B', 'C')
        expect(pipelines.map(&:status))
          .to contain_exactly('success', 'failed', 'skipped')
      end
    end

    context 'when ref is specified' do
      let(:pipelines) { described_class.latest('ref').all }

      it 'returns the latest pipeline for ref and different sha' do
        expect(pipelines.map(&:sha)).to contain_exactly('A', 'B')
        expect(pipelines.map(&:status))
          .to contain_exactly('success', 'failed')
      end
    end
  end

  describe '.latest_status' do
    include_context 'with some outdated pipelines'

    context 'when no ref is specified' do
      let(:latest_status) { described_class.latest_status }

      it 'returns the latest status for the same ref and different sha' do
        expect(latest_status).to eq(described_class.latest.status)
        expect(latest_status).to eq('failed')
      end
    end

    context 'when ref is specified' do
      let(:latest_status) { described_class.latest_status('ref') }

      it 'returns the latest status for ref and different sha' do
        expect(latest_status).to eq(described_class.latest_status('ref'))
        expect(latest_status).to eq('failed')
      end
    end
  end

  describe '.latest_successful_for' do
    include_context 'with some outdated pipelines'

    let!(:latest_successful_pipeline) do
      create_pipeline(:success, 'ref', 'D')
    end

    it 'returns the latest successful pipeline' do
      expect(described_class.latest_successful_for('ref'))
        .to eq(latest_successful_pipeline)
    end
  end

  describe '.latest_successful_for_refs' do
    include_context 'with some outdated pipelines'

    let!(:latest_successful_pipeline1) { create_pipeline(:success, 'ref1', 'D') }
    let!(:latest_successful_pipeline2) { create_pipeline(:success, 'ref2', 'D') }

    it 'returns the latest successful pipeline for both refs' do
      refs = %w(ref1 ref2 ref3)

      expect(described_class.latest_successful_for_refs(refs)).to eq({ 'ref1' => latest_successful_pipeline1, 'ref2' => latest_successful_pipeline2 })
    end
  end

  describe '.internal_sources' do
    subject { described_class.internal_sources }

    it { is_expected.to be_an(Array) }
  end

  describe '#status' do
    let(:build) do
      create(:ci_build, :created, pipeline: pipeline, name: 'test')
    end

    subject { pipeline.reload.status }

    context 'on queuing' do
      before do
        build.enqueue
      end

      it { is_expected.to eq('pending') }
    end

    context 'on run' do
      before do
        build.enqueue
        build.run
      end

      it { is_expected.to eq('running') }
    end

    context 'on drop' do
      before do
        build.drop
      end

      it { is_expected.to eq('failed') }
    end

    context 'on success' do
      before do
        build.success
      end

      it { is_expected.to eq('success') }
    end

    context 'on cancel' do
      before do
        build.cancel
      end

      context 'when build is pending' do
        let(:build) do
          create(:ci_build, :pending, pipeline: pipeline)
        end

        it { is_expected.to eq('canceled') }
      end
    end

    context 'on failure and build retry' do
      before do
        build.drop
        project.add_developer(user)

        Ci::Build.retry(build, user)
      end

      # We are changing a state: created > failed > running
      # Instead of: created > failed > pending
      # Since the pipeline already run, so it should not be pending anymore

      it { is_expected.to eq('running') }
    end
  end

  describe '#ci_yaml_file_path' do
    subject { pipeline.ci_yaml_file_path }

    it 'returns the path from project' do
      allow(pipeline.project).to receive(:ci_config_path) { 'custom/path' }

      is_expected.to eq('custom/path')
    end

    it 'returns default when custom path is nil' do
      allow(pipeline.project).to receive(:ci_config_path) { nil }

      is_expected.to eq('.gitlab-ci.yml')
    end

    it 'returns default when custom path is empty' do
      allow(pipeline.project).to receive(:ci_config_path) { '' }

      is_expected.to eq('.gitlab-ci.yml')
    end
  end

  describe '#ci_yaml_file' do
    it 'reports error if the file is not found' do
      allow(pipeline.project).to receive(:ci_config_path) { 'custom' }

      pipeline.ci_yaml_file

      expect(pipeline.yaml_errors)
        .to eq('Failed to load CI/CD config file at custom')
    end
  end

  describe '#detailed_status' do
    subject { pipeline.detailed_status(user) }

    context 'when pipeline is created' do
      let(:pipeline) { create(:ci_pipeline, status: :created) }

      it 'returns detailed status for created pipeline' do
        expect(subject.text).to eq 'created'
      end
    end

    context 'when pipeline is pending' do
      let(:pipeline) { create(:ci_pipeline, status: :pending) }

      it 'returns detailed status for pending pipeline' do
        expect(subject.text).to eq 'pending'
      end
    end

    context 'when pipeline is running' do
      let(:pipeline) { create(:ci_pipeline, status: :running) }

      it 'returns detailed status for running pipeline' do
        expect(subject.text).to eq 'running'
      end
    end

    context 'when pipeline is successful' do
      let(:pipeline) { create(:ci_pipeline, status: :success) }

      it 'returns detailed status for successful pipeline' do
        expect(subject.text).to eq 'passed'
      end
    end

    context 'when pipeline is failed' do
      let(:pipeline) { create(:ci_pipeline, status: :failed) }

      it 'returns detailed status for failed pipeline' do
        expect(subject.text).to eq 'failed'
      end
    end

    context 'when pipeline is canceled' do
      let(:pipeline) { create(:ci_pipeline, status: :canceled) }

      it 'returns detailed status for canceled pipeline' do
        expect(subject.text).to eq 'canceled'
      end
    end

    context 'when pipeline is skipped' do
      let(:pipeline) { create(:ci_pipeline, status: :skipped) }

      it 'returns detailed status for skipped pipeline' do
        expect(subject.text).to eq 'skipped'
      end
    end

    context 'when pipeline is blocked' do
      let(:pipeline) { create(:ci_pipeline, status: :manual) }

      it 'returns detailed status for blocked pipeline' do
        expect(subject.text).to eq 'blocked'
      end
    end

    context 'when pipeline is successful but with warnings' do
      let(:pipeline) { create(:ci_pipeline, status: :success) }

      before do
        create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline)
      end

      it 'retruns detailed status for successful pipeline with warnings' do
        expect(subject.label).to eq 'passed with warnings'
      end
    end
  end

  describe '#cancelable?' do
    %i[created running pending].each do |status0|
      context "when there is a build #{status0}" do
        before do
          create(:ci_build, status0, pipeline: pipeline)
        end

        it 'is cancelable' do
          expect(pipeline.cancelable?).to be_truthy
        end
      end

      context "when there is an external job #{status0}" do
        before do
          create(:generic_commit_status, status0, pipeline: pipeline)
        end

        it 'is cancelable' do
          expect(pipeline.cancelable?).to be_truthy
        end
      end

      %i[success failed canceled].each do |status1|
        context "when there are generic_commit_status jobs for #{status0} and #{status1}" do
          before do
            create(:generic_commit_status, status0, pipeline: pipeline)
            create(:generic_commit_status, status1, pipeline: pipeline)
          end

          it 'is cancelable' do
            expect(pipeline.cancelable?).to be_truthy
          end
        end

        context "when there are generic_commit_status and ci_build jobs for #{status0} and #{status1}" do
          before do
            create(:generic_commit_status, status0, pipeline: pipeline)
            create(:ci_build, status1, pipeline: pipeline)
          end

          it 'is cancelable' do
            expect(pipeline.cancelable?).to be_truthy
          end
        end

        context "when there are ci_build jobs for #{status0} and #{status1}" do
          before do
            create(:ci_build, status0, pipeline: pipeline)
            create(:ci_build, status1, pipeline: pipeline)
          end

          it 'is cancelable' do
            expect(pipeline.cancelable?).to be_truthy
          end
        end
      end
    end

    %i[success failed canceled].each do |status|
      context "when there is a build #{status}" do
        before do
          create(:ci_build, status, pipeline: pipeline)
        end

        it 'is not cancelable' do
          expect(pipeline.cancelable?).to be_falsey
        end
      end

      context "when there is an external job #{status}" do
        before do
          create(:generic_commit_status, status, pipeline: pipeline)
        end

        it 'is not cancelable' do
          expect(pipeline.cancelable?).to be_falsey
        end
      end
    end

    context 'when there is a manual action present in the pipeline' do
      before do
        create(:ci_build, :manual, pipeline: pipeline)
      end

      it 'is not cancelable' do
        expect(pipeline).not_to be_cancelable
      end
    end
  end

  describe '#cancel_running' do
    let(:latest_status) { pipeline.statuses.pluck(:status) }

    context 'when there is a running external job and a regular job' do
      before do
        create(:ci_build, :running, pipeline: pipeline)
        create(:generic_commit_status, :running, pipeline: pipeline)

        pipeline.cancel_running
      end

      it 'cancels both jobs' do
        expect(latest_status).to contain_exactly('canceled', 'canceled')
      end
    end

    context 'when jobs are in different stages' do
      before do
        create(:ci_build, :running, stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :running, stage_idx: 1, pipeline: pipeline)

        pipeline.cancel_running
      end

      it 'cancels both jobs' do
        expect(latest_status).to contain_exactly('canceled', 'canceled')
      end
    end

    context 'when there are created builds present in the pipeline' do
      before do
        create(:ci_build, :running, stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :created, stage_idx: 1, pipeline: pipeline)

        pipeline.cancel_running
      end

      it 'cancels created builds' do
        expect(latest_status).to eq %w(canceled canceled)
      end
    end
  end

  describe '#retry_failed' do
    let(:latest_status) { pipeline.statuses.latest.pluck(:status) }

    before do
      project.add_developer(user)
    end

    context 'when there is a failed build and failed external status' do
      before do
        create(:ci_build, :failed, name: 'build', pipeline: pipeline)
        create(:generic_commit_status, :failed, name: 'jenkins', pipeline: pipeline)

        pipeline.retry_failed(user)
      end

      it 'retries only build' do
        expect(latest_status).to contain_exactly('pending', 'failed')
      end
    end

    context 'when builds are in different stages' do
      before do
        create(:ci_build, :failed, name: 'build', stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :failed, name: 'jenkins', stage_idx: 1, pipeline: pipeline)

        pipeline.retry_failed(user)
      end

      it 'retries both builds' do
        expect(latest_status).to contain_exactly('pending', 'created')
      end
    end

    context 'when there are canceled and failed' do
      before do
        create(:ci_build, :failed, name: 'build', stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :canceled, name: 'jenkins', stage_idx: 1, pipeline: pipeline)

        pipeline.retry_failed(user)
      end

      it 'retries both builds' do
        expect(latest_status).to contain_exactly('pending', 'created')
      end
    end
  end

  describe '#execute_hooks' do
    let!(:build_a) { create_build('a', 0) }
    let!(:build_b) { create_build('b', 1) }

    let!(:hook) do
      create(:project_hook, project: project, pipeline_events: enabled)
    end

    before do
      WebHookWorker.drain
    end

    context 'with pipeline hooks enabled' do
      let(:enabled) { true }

      before do
        WebMock.stub_request(:post, hook.url)
      end

      context 'with multiple builds' do
        context 'when build is queued' do
          before do
            build_a.enqueue
            build_b.enqueue
          end

          it 'receives a pending event once' do
            expect(WebMock).to have_requested_pipeline_hook('pending').once
          end
        end

        context 'when build is run' do
          before do
            build_a.enqueue
            build_a.run
            build_b.enqueue
            build_b.run
          end

          it 'receives a running event once' do
            expect(WebMock).to have_requested_pipeline_hook('running').once
          end
        end

        context 'when all builds succeed' do
          before do
            build_a.success

            # We have to reload build_b as this is in next stage and it gets triggered by PipelineProcessWorker
            build_b.reload.success
          end

          it 'receives a success event once' do
            expect(WebMock).to have_requested_pipeline_hook('success').once
          end
        end

        context 'when stage one failed' do
          before do
            build_a.drop
          end

          it 'receives a failed event once' do
            expect(WebMock).to have_requested_pipeline_hook('failed').once
          end
        end

        def have_requested_pipeline_hook(status)
          have_requested(:post, hook.url).with do |req|
            json_body = JSON.parse(req.body)
            json_body['object_attributes']['status'] == status &&
              json_body['builds'].length == 2
          end
        end
      end
    end

    context 'with pipeline hooks disabled' do
      let(:enabled) { false }

      before do
        build_a.enqueue
        build_b.enqueue
      end

      it 'did not execute pipeline_hook after touched' do
        expect(WebMock).not_to have_requested(:post, hook.url)
      end
    end

    def create_build(name, stage_idx)
      create(:ci_build,
             :created,
             pipeline: pipeline,
             name: name,
             stage_idx: stage_idx)
    end
  end

  describe "#merge_requests" do
    let(:project) { create(:empty_project) }
    let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master', sha: 'a288a022a53a5a944fae87bcec6efc87b7061808') }

    it "returns merge requests whose `diff_head_sha` matches the pipeline's SHA" do
      allow_any_instance_of(MergeRequest).to receive(:diff_head_sha) { 'a288a022a53a5a944fae87bcec6efc87b7061808' }
      merge_request = create(:merge_request, source_project: project, head_pipeline: pipeline, source_branch: pipeline.ref)

      expect(pipeline.merge_requests).to eq([merge_request])
    end

    it "doesn't return merge requests whose source branch doesn't match the pipeline's ref" do
      create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master')

      expect(pipeline.merge_requests).to be_empty
    end

    it "doesn't return merge requests whose `diff_head_sha` doesn't match the pipeline's SHA" do
      create(:merge_request, source_project: project, source_branch: pipeline.ref)
      allow_any_instance_of(MergeRequest).to receive(:diff_head_sha) { '97de212e80737a608d939f648d959671fb0a0142b' }

      expect(pipeline.merge_requests).to be_empty
    end
  end

  describe "#all_merge_requests" do
    let(:project) { create(:empty_project) }
    let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master') }

    it "returns all merge requests having the same source branch" do
      merge_request = create(:merge_request, source_project: project, source_branch: pipeline.ref)

      expect(pipeline.all_merge_requests).to eq([merge_request])
    end

    it "doesn't return merge requests having a different source branch" do
      create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master')

      expect(pipeline.all_merge_requests).to be_empty
    end
  end

  describe '#stuck?' do
    before do
      create(:ci_build, :pending, pipeline: pipeline)
    end

    context 'when pipeline is stuck' do
      it 'is stuck' do
        expect(pipeline).to be_stuck
      end
    end

    context 'when pipeline is not stuck' do
      before do
        create(:ci_runner, :shared, :online)
      end

      it 'is not stuck' do
        expect(pipeline).not_to be_stuck
      end
    end
  end

  describe '#has_yaml_errors?' do
    context 'when pipeline has errors' do
      let(:pipeline) do
        create(:ci_pipeline, config: { rspec: nil })
      end

      it 'contains yaml errors' do
        expect(pipeline).to have_yaml_errors
      end
    end

    context 'when pipeline does not have errors' do
      let(:pipeline) do
        create(:ci_pipeline, config: { rspec: { script: 'rake test' } })
      end

      it 'does not containyaml errors' do
        expect(pipeline).not_to have_yaml_errors
      end
    end
  end

  describe 'notifications when pipeline success or failed' do
    let(:project) { create(:project, :repository) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project,
             sha: project.commit('master').sha,
             user: create(:user))
    end

    before do
      project.team << [pipeline.user, Gitlab::Access::DEVELOPER]

      pipeline.user.global_notification_setting
        .update(level: 'custom', failed_pipeline: true, success_pipeline: true)

      reset_delivered_emails!

      perform_enqueued_jobs do
        pipeline.enqueue
        pipeline.run
      end
    end

    shared_examples 'sending a notification' do
      it 'sends an email' do
        should_only_email(pipeline.user, kind: :bcc)
      end
    end

    shared_examples 'not sending any notification' do
      it 'does not send any email' do
        should_not_email_anyone
      end
    end

    context 'with success pipeline' do
      before do
        perform_enqueued_jobs do
          pipeline.succeed
        end
      end

      it_behaves_like 'sending a notification'
    end

    context 'with failed pipeline' do
      before do
        perform_enqueued_jobs do
          create(:ci_build, :failed, pipeline: pipeline)
          create(:generic_commit_status, :failed, pipeline: pipeline)

          pipeline.drop
        end
      end

      it_behaves_like 'sending a notification'
    end

    context 'with skipped pipeline' do
      before do
        perform_enqueued_jobs do
          pipeline.skip
        end
      end

      it_behaves_like 'not sending any notification'
    end

    context 'with cancelled pipeline' do
      before do
        perform_enqueued_jobs do
          pipeline.cancel
        end
      end

      it_behaves_like 'not sending any notification'
    end
  end

  describe '#codeclimate_artifact' do
    context 'has codeclimate build' do
      let!(:build) do
        create(
          :ci_build,
          :artifacts,
          name: 'codeclimate',
          pipeline: pipeline,
          options: {
            artifacts: {
              paths: ['codeclimate.json']
            }
          }
        )
      end

      it { expect(pipeline.codeclimate_artifact).to eq(build) }
    end

    context 'no codeclimate build' do
      before do
        create(:ci_build, pipeline: pipeline)
      end

      it { expect(pipeline.codeclimate_artifact).to be_nil }
    end
  end
end
