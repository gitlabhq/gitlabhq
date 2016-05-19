require 'spec_helper'

describe Ci::Commit, models: true do
  let(:project) { FactoryGirl.create :empty_project }
  let(:commit) { FactoryGirl.create :ci_commit, project: project }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:statuses) }
  it { is_expected.to have_many(:trigger_requests) }
  it { is_expected.to have_many(:builds) }
  it { is_expected.to validate_presence_of :sha }
  it { is_expected.to validate_presence_of :status }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :short_sha }

  describe :valid_commit_sha do
    context 'commit.sha can not start with 00000000' do
      before do
        commit.sha = '0' * 40
        commit.valid_commit_sha
      end

      it('commit errors should not be empty') { expect(commit.errors).not_to be_empty }
    end
  end

  describe :short_sha do
    subject { commit.short_sha }

    it 'has 8 items' do
      expect(subject.size).to eq(8)
    end
    it { expect(commit.sha).to start_with(subject) }
  end

  describe :create_next_builds do
  end

  describe :retried do
    subject { commit.retried }

    before do
      @commit1 = FactoryGirl.create :ci_build, commit: commit, name: 'deploy'
      @commit2 = FactoryGirl.create :ci_build, commit: commit, name: 'deploy'
    end

    it 'returns old builds' do
      is_expected.to contain_exactly(@commit1)
    end
  end

  describe :create_builds do
    let!(:commit) { FactoryGirl.create :ci_commit, project: project, ref: 'master', tag: false }

    def create_builds(trigger_request = nil)
      commit.create_builds(nil, trigger_request)
    end

    def create_next_builds
      commit.create_next_builds(commit.builds.order(:id).last)
    end

    it 'creates builds' do
      expect(create_builds).to be_truthy
      commit.builds.update_all(status: "success")
      expect(commit.builds.count(:all)).to eq(2)

      expect(create_next_builds).to be_truthy
      commit.builds.update_all(status: "success")
      expect(commit.builds.count(:all)).to eq(4)

      expect(create_next_builds).to be_truthy
      commit.builds.update_all(status: "success")
      expect(commit.builds.count(:all)).to eq(5)

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
        stub_ci_commit_yaml_file(YAML.dump(yaml))
        create_builds
      end

      it 'properly schedules builds' do
        expect(commit.builds.pluck(:status)).to contain_exactly('pending')
        commit.builds.running_or_pending.each(&:drop)
        expect(commit.builds.pluck(:status)).to contain_exactly('pending', 'failed')
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
        stub_ci_commit_yaml_file(YAML.dump(yaml))
      end

      context 'when builds are successful' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(commit.builds.pluck(:name)).to contain_exactly('build')
          expect(commit.builds.pluck(:status)).to contain_exactly('pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'success')
          commit.reload
          expect(commit.status).to eq('success')
        end
      end

      context 'when test job fails' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(commit.builds.pluck(:name)).to contain_exactly('build')
          expect(commit.builds.pluck(:status)).to contain_exactly('pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'pending')
          commit.builds.running_or_pending.each(&:drop)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'failed', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'failed', 'success', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'failed', 'success', 'success')
          commit.reload
          expect(commit.status).to eq('failed')
        end
      end

      context 'when test and test_failure jobs fail' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(commit.builds.pluck(:name)).to contain_exactly('build')
          expect(commit.builds.pluck(:status)).to contain_exactly('pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'pending')
          commit.builds.running_or_pending.each(&:drop)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'failed', 'pending')
          commit.builds.running_or_pending.each(&:drop)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'failed', 'failed', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'test_failure', 'cleanup')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'failed', 'failed', 'success')
          commit.reload
          expect(commit.status).to eq('failed')
        end
      end

      context 'when deploy job fails' do
        it 'properly creates builds' do
          expect(create_builds).to be_truthy
          expect(commit.builds.pluck(:name)).to contain_exactly('build')
          expect(commit.builds.pluck(:status)).to contain_exactly('pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
          commit.builds.running_or_pending.each(&:drop)

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'failed', 'pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'failed', 'success')
          commit.reload
          expect(commit.status).to eq('failed')
        end
      end

      context 'when build is canceled in the second stage' do
        it 'does not schedule builds after build has been canceled' do
          expect(create_builds).to be_truthy
          expect(commit.builds.pluck(:name)).to contain_exactly('build')
          expect(commit.builds.pluck(:status)).to contain_exactly('pending')
          commit.builds.running_or_pending.each(&:success)

          expect(commit.builds.running_or_pending).to_not be_empty

          expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test')
          expect(commit.builds.pluck(:status)).to contain_exactly('success', 'pending')
          commit.builds.running_or_pending.each(&:cancel)

          expect(commit.builds.running_or_pending).to be_empty
          expect(commit.reload.status).to eq('canceled')
        end
      end
    end
  end

  describe "#finished_at" do
    let(:commit) { FactoryGirl.create :ci_commit }

    it "returns finished_at of latest build" do
      build = FactoryGirl.create :ci_build, commit: commit, finished_at: Time.now - 60
      FactoryGirl.create :ci_build, commit: commit, finished_at: Time.now - 120

      expect(commit.finished_at.to_i).to eq(build.finished_at.to_i)
    end

    it "returns nil if there is no finished build" do
      FactoryGirl.create :ci_not_started_build, commit: commit

      expect(commit.finished_at).to be_nil
    end
  end

  describe "coverage" do
    let(:project) { FactoryGirl.create :empty_project, build_coverage_regex: "/.*/" }
    let(:commit) { FactoryGirl.create :ci_commit, project: project }

    it "calculates average when there are two builds with coverage" do
      FactoryGirl.create :ci_build, name: "rspec", coverage: 30, commit: commit
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 40, commit: commit
      expect(commit.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one with nil" do
      FactoryGirl.create :ci_build, name: "rspec", coverage: 30, commit: commit
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 40, commit: commit
      FactoryGirl.create :ci_build, commit: commit
      expect(commit.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one is retried" do
      FactoryGirl.create :ci_build, name: "rspec", coverage: 30, commit: commit
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 30, commit: commit
      FactoryGirl.create :ci_build, name: "rubocop", coverage: 40, commit: commit
      expect(commit.coverage).to eq("35.00")
    end

    it "calculates average when there is one build without coverage" do
      FactoryGirl.create :ci_build, commit: commit
      expect(commit.coverage).to be_nil
    end
  end

  describe '#retryable?' do
    subject { commit.retryable? }

    context 'no failed builds' do
      before do
        FactoryGirl.create :ci_build, name: "rspec", commit: commit, status: 'success'
      end

      it 'be not retryable' do
        is_expected.to be_falsey
      end
    end

    context 'with failed builds' do
      before do
        FactoryGirl.create :ci_build, name: "rspec", commit: commit, status: 'running'
        FactoryGirl.create :ci_build, name: "rubocop", commit: commit, status: 'failed'
      end

      it 'be retryable' do
        is_expected.to be_truthy
      end
    end
  end

  describe '#stages' do
    let(:commit2) { FactoryGirl.create :ci_commit, project: project }
    subject { CommitStatus.where(commit: [commit, commit2]).stages }

    before do
      FactoryGirl.create :ci_build, commit: commit2, stage: 'test', stage_idx: 1
      FactoryGirl.create :ci_build, commit: commit, stage: 'build', stage_idx: 0
    end

    it 'return all stages' do
      is_expected.to eq(%w(build test))
    end
  end

  describe '#update_state' do
    it 'execute update_state after touching object' do
      expect(commit).to receive(:update_state).and_return(true)
      commit.touch
    end

    context 'dependent objects' do
      let(:commit_status) { build :commit_status, commit: commit }

      it 'execute update_state after saving dependent object' do
        expect(commit).to receive(:update_state).and_return(true)
        commit_status.save
      end
    end

    context 'update state' do
      let(:current) { Time.now.change(usec: 0) }
      let(:build) { FactoryGirl.create :ci_build, :success, commit: commit, started_at: current - 120, finished_at: current - 60 }

      before do
        build
      end

      [:status, :started_at, :finished_at, :duration].each do |param|
        it "update #{param}" do
          expect(commit.send(param)).to eq(build.send(param))
        end
      end
    end
  end

  describe '#branch?' do
    subject { commit.branch? }

    context 'is not a tag' do
      before do
        commit.tag = false
      end

      it 'return true when tag is set to false' do
        is_expected.to be_truthy
      end
    end

    context 'is not a tag' do
      before do
        commit.tag = true
      end

      it 'return false when tag is set to true' do
        is_expected.to be_falsey
      end
    end
  end
end
