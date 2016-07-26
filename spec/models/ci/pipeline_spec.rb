require 'spec_helper'

describe Ci::Pipeline, models: true do
  let(:project) { FactoryGirl.create :empty_project }
  let(:pipeline) { FactoryGirl.create :ci_pipeline, project: project }

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

  describe '#create_next_builds' do
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

  describe '#create_builds' do
    let!(:pipeline) { FactoryGirl.create :ci_pipeline, project: project, ref: 'master', tag: false }

    def create_builds(trigger_request = nil)
      pipeline.create_builds(nil, trigger_request)
    end

    def create_next_builds
      pipeline.create_next_builds(pipeline.builds.order(:id).last)
    end

    it 'creates builds' do
      expect(create_builds).to be_truthy
      pipeline.builds.update_all(status: "success")
      expect(pipeline.builds.count(:all)).to eq(2)

      expect(create_next_builds).to be_truthy
      pipeline.builds.update_all(status: "success")
      expect(pipeline.builds.count(:all)).to eq(4)

      expect(create_next_builds).to be_truthy
      pipeline.builds.update_all(status: "success")
      expect(pipeline.builds.count(:all)).to eq(5)

      expect(create_next_builds).to be_falsey
    end

    context 'custom stage with first job allowed to fail' do
      let(:yaml) do
        {
          stages: ['clean', 'test'],
          clean_job: {
            stage: 'clean',
            allow_failure: true,
            script: 'BUILD',
          },
          test_job: {
            stage: 'test',
            script: 'TEST',
          },
        }
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(yaml))
        create_builds
      end

      it 'properly schedules builds' do
        expect(pipeline.builds.pluck(:status)).to contain_exactly('pending')
        pipeline.builds.running_or_pending.each(&:drop)
        expect(pipeline.builds.pluck(:status)).to contain_exactly('pending', 'failed')
      end
    end

    context 'properly creates builds when "when" is defined' do
      let(:yaml) do
        {
          stages: ["build", "test", "test_failure", "deploy", "cleanup"],
          build: {
            stage: "build",
            script: "BUILD",
          },
          test: {
            stage: "test",
            script: "TEST",
          },
          test_failure: {
            stage: "test_failure",
            script: "ON test failure",
            when: "on_failure",
          },
          deploy: {
            stage: "deploy",
            script: "PUBLISH",
          },
          cleanup: {
            stage: "cleanup",
            script: "TIDY UP",
            when: "always",
          }
        }
      end

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(yaml))
      end

      context 'when builds are successful' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(pipeline.builds.pluck(:name)).to contain_exactly('build')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('success')
        end
      end

      context 'when test job fails' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(pipeline.builds.pluck(:name)).to contain_exactly('build')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'failed', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'failed', 'success', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('failed')
        end
      end

      context 'when test and test_failure jobs fail' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(pipeline.builds.pluck(:name)).to contain_exactly('build')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'failed', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'failed', 'failed', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('failed')
        end
      end

      context 'when deploy job fails' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(pipeline.builds.pluck(:name)).to contain_exactly('build')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
          pipeline.builds.running_or_pending.each(&:drop)

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'success', 'failed', 'pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'success', 'failed', 'success')
          pipeline.reload
          expect(pipeline.status).to eq('failed')
        end
      end

      context 'when build is canceled in the second stage' do
        it 'does not schedule builds after build has been canceled' do
          expect(create_builds).to be_truthy
          expect(pipeline.builds.pluck(:name)).to contain_exactly('build')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('pending')
          pipeline.builds.running_or_pending.each(&:success)

          expect(pipeline.builds.running_or_pending).not_to be_empty

          expect(pipeline.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(pipeline.builds.pluck(:status)).to contain_exactly('success', 'pending')
          pipeline.builds.running_or_pending.each(&:cancel)

          expect(pipeline.builds.running_or_pending).to be_empty
          expect(pipeline.reload.status).to eq('canceled')
        end
      end

      context 'when listing manual actions' do
        let(:yaml) do
          {
            stages: ["build", "test", "staging", "production", "cleanup"],
            build: {
              stage: "build",
              script: "BUILD",
            },
            test: {
              stage: "test",
              script: "TEST",
            },
            staging: {
              stage: "staging",
              script: "PUBLISH",
            },
            production: {
              stage: "production",
              script: "PUBLISH",
              when: "manual",
            },
            cleanup: {
              stage: "cleanup",
              script: "TIDY UP",
              when: "always",
            },
            clear_cache: {
              stage: "cleanup",
              script: "CLEAR CACHE",
              when: "manual",
            }
          }
        end

        it 'returns only for skipped builds' do
          # currently all builds are created
          expect(create_builds).to be_truthy
          expect(manual_actions).to be_empty

          # succeed stage build
          pipeline.builds.running_or_pending.each(&:success)
          expect(manual_actions).to be_empty

          # succeed stage test
          pipeline.builds.running_or_pending.each(&:success)
          expect(manual_actions).to be_empty

          # succeed stage staging and skip stage production
          pipeline.builds.running_or_pending.each(&:success)
          expect(manual_actions).to be_many # production and clear cache

          # succeed stage cleanup
          pipeline.builds.running_or_pending.each(&:success)

          # after processing a pipeline we should have 6 builds, 5 succeeded
          expect(pipeline.builds.count).to eq(6)
          expect(pipeline.builds.success.count).to eq(4)
        end

        def manual_actions
          pipeline.manual_actions
        end
      end
    end

    context 'when no builds created' do
      let(:pipeline) { build(:ci_pipeline) }

      before do
        stub_ci_pipeline_yaml_file(YAML.dump(before_script: ['ls']))
      end

      it 'returns false' do
        expect(pipeline.create_builds(nil)).to be_falsey
        expect(pipeline).not_to be_persisted
      end
    end
  end

  describe "#finished_at" do
    let(:pipeline) { FactoryGirl.create :ci_pipeline }

    it "returns finished_at of latest build" do
      build = FactoryGirl.create :ci_build, pipeline: pipeline, finished_at: Time.now - 60
      FactoryGirl.create :ci_build, pipeline: pipeline, finished_at: Time.now - 120

      expect(pipeline.finished_at.to_i).to eq(build.finished_at.to_i)
    end

    it "returns nil if there is no finished build" do
      FactoryGirl.create :ci_not_started_build, pipeline: pipeline

      expect(pipeline.finished_at).to be_nil
    end
  end

  describe "coverage" do
    let(:project) { FactoryGirl.create :empty_project, build_coverage_regex: "/.*/" }
    let(:pipeline) { FactoryGirl.create :ci_pipeline, project: project }

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

  describe '#update_state' do
    it 'execute update_state after touching object' do
      expect(pipeline).to receive(:update_state).and_return(true)
      pipeline.touch
    end

    context 'dependent objects' do
      let(:commit_status) { build :commit_status, pipeline: pipeline }

      it 'execute update_state after saving dependent object' do
        expect(pipeline).to receive(:update_state).and_return(true)
        commit_status.save
      end
    end

    context 'update state' do
      let(:current) { Time.now.change(usec: 0) }
      let(:build) { FactoryGirl.create :ci_build, :success, pipeline: pipeline, started_at: current - 120, finished_at: current - 60 }

      before do
        build
      end

      [:status, :started_at, :finished_at, :duration].each do |param|
        it "update #{param}" do
          expect(pipeline.send(param)).to eq(build.send(param))
        end
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
end
