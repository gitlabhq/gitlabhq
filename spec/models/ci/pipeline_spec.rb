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
        FactoryGirl.create :ci_build, name: "rspec", pipeline: pipeline, status: 'success'
      end

      it 'be not retryable' do
        is_expected.to be_falsey
      end
    end

    context 'with failed builds' do
      before do
        FactoryGirl.create :ci_build, name: "rspec", pipeline: pipeline, status: 'running'
        FactoryGirl.create :ci_build, name: "rubocop", pipeline: pipeline, status: 'failed'
      end

      it 'be retryable' do
        is_expected.to be_truthy
      end
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
    let(:build) { create :ci_build, name: 'build1', pipeline: pipeline }

    describe '#duration' do
      before do
        travel_to(current - 120) do
          pipeline.run
        end

        travel_to(current) do
          pipeline.succeed
        end
      end

      it 'matches sum of builds duration' do
        expect(pipeline.reload.duration).to eq(120)
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
    let!(:build_a) { create_build('a') }
    let!(:build_b) { create_build('b') }

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

          it 'receive a pending event once' do
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

          it 'receive a running event once' do
            expect(WebMock).to have_requested_pipeline_hook('running').once
          end
        end

        context 'when all builds succeed' do
          before do
            build_a.success
            build_b.success
          end

          it 'receive a success event once' do
            expect(WebMock).to have_requested_pipeline_hook('success').once
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

    def create_build(name)
      create(:ci_build, :created, pipeline: pipeline, name: name)
    end
  end
end
