require 'spec_helper'

describe Ci::Pipeline, models: true do
  let(:project) { FactoryGirl.create :empty_project }
  let(:pipeline) { FactoryGirl.create :ci_empty_pipeline, status: 'created', project: project }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to have_many(:statuses) }
  it { is_expected.to have_many(:trigger_requests) }
  it { is_expected.to have_many(:builds) }

  it { is_expected.to validate_presence_of :sha }
  it { is_expected.to validate_presence_of :status }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :short_sha }

  it { is_expected.to delegate_method(:stages).to(:statuses) }

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
      @build1 = FactoryGirl.create :ci_build, pipeline: pipeline, name: 'deploy'
      @build2 = FactoryGirl.create :ci_build, pipeline: pipeline, name: 'deploy'
    end

    it 'returns old builds' do
      is_expected.to contain_exactly(@build1)
    end
  end

  describe "coverage" do
    let(:project) { FactoryGirl.create :empty_project, build_coverage_regex: "/.*/" }
    let(:pipeline) { FactoryGirl.create :ci_empty_pipeline, project: project }

    it "calculates average when there are two builds with coverage" do
      FactoryGirl.create :ci_build, name: "rspec", coverage: 30, pipeline: pipeline
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 40, pipeline: pipeline
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one with nil" do
      FactoryGirl.create :ci_build, name: "rspec", coverage: 30, pipeline: pipeline
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 40, pipeline: pipeline
      FactoryGirl.create :ci_build, pipeline: pipeline
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one is retried" do
      FactoryGirl.create :ci_build, name: "rspec", coverage: 30, pipeline: pipeline
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 30, pipeline: pipeline
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 40, pipeline: pipeline
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there is one build without coverage" do
      FactoryGirl.create :ci_build, pipeline: pipeline
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

  describe '#stages' do
    let(:pipeline2) { FactoryGirl.create :ci_pipeline, project: project }
    subject { CommitStatus.where(pipeline: [pipeline, pipeline2]).stages }

    before do
      FactoryGirl.create :ci_build, pipeline: pipeline2, stage: 'test', stage_idx: 1
      FactoryGirl.create :ci_build, pipeline: pipeline, stage: 'build', stage_idx: 0
    end

    it 'return all stages' do
      is_expected.to eq(%w(build test))
    end
  end

  describe 'state machine' do
    let(:current) { Time.now.change(usec: 0) }
    let(:build) { create_build('build1', 0) }
    let(:build_b) { create_build('build2', 0) }
    let(:build_c) { create_build('build3', 0) }

    describe '#duration' do
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
      let(:project) { FactoryGirl.create :project }
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

    def create_build(name, queued_at = current, started_from = 0)
      create(:ci_build,
             name: name,
             pipeline: pipeline,
             queued_at: queued_at,
             started_at: queued_at + started_from)
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
    let(:project) { create(:project) }

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

        it 'returns latest one' do
          is_expected.to contain_exactly(manual2)
        end
      end
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

  describe '#status' do
    let!(:build) { create(:ci_build, :created, pipeline: pipeline, name: 'test') }

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

      it { is_expected.to eq('canceled') }
    end

    context 'on failure and build retry' do
      before do
        build.drop
        Ci::Build.retry(build)
      end

      # We are changing a state: created > failed > running
      # Instead of: created > failed > pending
      # Since the pipeline already run, so it should not be pending anymore

      it { is_expected.to eq('running') }
    end
  end

  describe '#execute_hooks' do
    let!(:build_a) { create_build('a', 0) }
    let!(:build_b) { create_build('b', 1) }

    let!(:hook) do
      create(:project_hook, project: project, pipeline_events: enabled)
    end

    before do
      ProjectWebHookWorker.drain
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
    let(:project) { FactoryGirl.create :project }
    let(:pipeline) { FactoryGirl.create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master', sha: project.repository.commit('master').id) }

    it "returns merge requests whose `diff_head_sha` matches the pipeline's SHA" do
      merge_request = create(:merge_request, source_project: project, source_branch: pipeline.ref)

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

  describe 'notifications when pipeline success or failed' do
    let(:project) { create(:project) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project,
             sha: project.commit('master').sha,
             user: create(:user))
    end

    before do
      reset_delivered_emails!

      project.team << [pipeline.user, Gitlab::Access::DEVELOPER]

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
end
