# == Schema Information
#
# Table name: ci_commits
#
#  id            :integer          not null, primary key
#  project_id    :integer
#  ref           :string(255)
#  sha           :string(255)
#  before_sha    :string(255)
#  push_data     :text
#  created_at    :datetime
#  updated_at    :datetime
#  tag           :boolean          default(FALSE)
#  yaml_errors   :text
#  committed_at  :datetime
#  gl_project_id :integer
#

require 'spec_helper'

describe Ci::Commit do
  let(:project) { FactoryGirl.create :ci_project }
  let(:gl_project) { FactoryGirl.create :empty_project, gitlab_ci_project: project }
  let(:commit) { FactoryGirl.create :ci_commit, gl_project: gl_project }

  it { is_expected.to belong_to(:gl_project) }
  it { is_expected.to have_many(:statuses) }
  it { is_expected.to have_many(:trigger_requests) }
  it { is_expected.to have_many(:builds) }
  it { is_expected.to validate_presence_of :sha }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :short_sha }

  describe :ordered do
    let(:project) { FactoryGirl.create :empty_project }

    it 'returns ordered list of commits' do
      commit1 = FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, gl_project: project
      commit2 = FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, gl_project: project
      expect(project.ci_commits.ordered).to eq([commit2, commit1])
    end

    it 'returns commits ordered by committed_at and id, with nulls last' do
      commit1 = FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, gl_project: project
      commit2 = FactoryGirl.create :ci_commit, committed_at: nil, gl_project: project
      commit3 = FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, gl_project: project
      commit4 = FactoryGirl.create :ci_commit, committed_at: nil, gl_project: project
      expect(project.ci_commits.ordered).to eq([commit2, commit4, commit3, commit1])
    end
  end

  describe :last_build do
    subject { commit.last_build }
    before do
      @first = FactoryGirl.create :ci_build, commit: commit, created_at: Date.yesterday
      @second = FactoryGirl.create :ci_build, commit: commit
    end

    it { is_expected.to be_a(Ci::Build) }
    it('returns with the most recently created build') { is_expected.to eq(@second) }
  end

  describe :retry do
    before do
      @first = FactoryGirl.create :ci_build, commit: commit, created_at: Date.yesterday
      @second = FactoryGirl.create :ci_build, commit: commit
    end

    it "creates only a new build" do
      expect(commit.builds.count(:all)).to eq 2
      expect(commit.statuses.count(:all)).to eq 2
      commit.retry
      expect(commit.builds.count(:all)).to eq 3
      expect(commit.statuses.count(:all)).to eq 3
    end
  end

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

  describe :stage do
    subject { commit.stage }

    before do
      @second = FactoryGirl.create :commit_status, commit: commit, name: 'deploy', stage: 'deploy', stage_idx: 1, status: 'pending'
      @first = FactoryGirl.create :commit_status, commit: commit, name: 'test', stage: 'test', stage_idx: 0, status: 'pending'
    end

    it 'returns first running stage' do
      is_expected.to eq('test')
    end

    context 'first build succeeded' do
      before do
        @first.success
      end

      it 'returns last running stage' do
        is_expected.to eq('deploy')
      end
    end

    context 'all builds succeeded' do
      before do
        @first.success
        @second.success
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe :create_next_builds do
  end

  describe :refs do
    subject { commit.refs }

    before do
      FactoryGirl.create :commit_status, commit: commit, name: 'deploy'
      FactoryGirl.create :commit_status, commit: commit, name: 'deploy', ref: 'develop'
      FactoryGirl.create :commit_status, commit: commit, name: 'deploy', ref: 'master'
    end

    it 'returns all refs' do
      is_expected.to contain_exactly('master', 'develop', nil)
    end
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
    let!(:commit) { FactoryGirl.create :ci_commit, gl_project: gl_project }

    def create_builds(trigger_request = nil)
      commit.create_builds('master', false, nil, trigger_request)
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

    context 'for different ref' do
      def create_develop_builds
        commit.create_builds('develop', false, nil, nil)
      end

      it 'creates builds' do
        expect(create_builds).to be_truthy
        commit.builds.update_all(status: "success")
        expect(commit.builds.count(:all)).to eq(2)

        expect(create_develop_builds).to be_truthy
        commit.builds.update_all(status: "success")
        expect(commit.builds.count(:all)).to eq(4)
        expect(commit.refs.size).to eq(2)
        expect(commit.builds.pluck(:name).uniq.size).to eq(2)
      end
    end

    context 'for build triggers' do
      let(:trigger) { FactoryGirl.create :ci_trigger, project: project }
      let(:trigger_request) { FactoryGirl.create :ci_trigger_request, commit: commit, trigger: trigger }

      it 'creates builds' do
        expect(create_builds(trigger_request)).to be_truthy
        expect(commit.builds.count(:all)).to eq(2)
      end

      it 'rebuilds commit' do
        expect(create_builds).to be_truthy
        expect(commit.builds.count(:all)).to eq(2)

        expect(create_builds(trigger_request)).to be_truthy
        expect(commit.builds.count(:all)).to eq(4)
      end

      it 'creates next builds' do
        expect(create_builds(trigger_request)).to be_truthy
        expect(commit.builds.count(:all)).to eq(2)
        commit.builds.update_all(status: "success")

        expect(create_next_builds).to be_truthy
        expect(commit.builds.count(:all)).to eq(4)
      end

      context 'for [ci skip]' do
        before do
          allow(commit).to receive(:git_commit_message) { 'message [ci skip]' }
        end

        it 'rebuilds commit' do
          expect(commit.status).to eq('skipped')
          expect(create_builds).to be_truthy

          # since everything in Ci::Commit is cached we need to fetch a new object
          new_commit = Ci::Commit.find_by_id(commit.id)
          expect(new_commit.status).to eq('pending')
        end
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

      it 'properly creates builds' do
        expect(create_builds).to be_truthy
        expect(commit.builds.pluck(:name)).to contain_exactly('build')
        expect(commit.builds.pluck(:status)).to contain_exactly('pending')
        commit.builds.running_or_pending.each(&:success)

        expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test')
        expect(commit.builds.pluck(:status)).to contain_exactly('success', 'pending')
        commit.builds.running_or_pending.each(&:success)

        expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'pending')
        expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy')
        commit.builds.running_or_pending.each(&:success)

        expect(commit.builds.pluck(:name)).to contain_exactly('build', 'test', 'deploy', 'cleanup')
        expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'pending')
        commit.builds.running_or_pending.each(&:success)

        expect(commit.builds.pluck(:status)).to contain_exactly('success', 'success', 'success', 'success')
        expect(commit.status).to eq('success')
      end

      it 'properly creates builds when test fails' do
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
        expect(commit.status).to eq('failed')
      end

      it 'properly creates builds when test and test_failure fails' do
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
        expect(commit.status).to eq('failed')
      end

      it 'properly creates builds when deploy fails' do
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
        expect(commit.status).to eq('failed')
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
    let(:project) { FactoryGirl.create :ci_project, coverage_regex: "/.*/" }
    let(:gl_project) { FactoryGirl.create :empty_project, gitlab_ci_project: project }
    let(:commit) { FactoryGirl.create :ci_commit, gl_project: gl_project }

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
end
