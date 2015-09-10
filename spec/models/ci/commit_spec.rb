# == Schema Information
#
# Table name: commits
#
#  id           :integer          not null, primary key
#  project_id   :integer
#  ref          :string(255)
#  sha          :string(255)
#  before_sha   :string(255)
#  push_data    :text
#  created_at   :datetime
#  updated_at   :datetime
#  tag          :boolean          default(FALSE)
#  yaml_errors  :text
#  committed_at :datetime
#

require 'spec_helper'

describe Ci::Commit do
  let(:project) { FactoryGirl.create :ci_project }
  let(:commit) { FactoryGirl.create :ci_commit, project: project }
  let(:commit_with_project) { FactoryGirl.create :ci_commit, project: project }
  let(:config_processor) { Ci::GitlabCiYamlProcessor.new(gitlab_ci_yaml) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:builds) }
  it { is_expected.to validate_presence_of :before_sha }
  it { is_expected.to validate_presence_of :sha }
  it { is_expected.to validate_presence_of :ref }
  it { is_expected.to validate_presence_of :push_data }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :short_sha }

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

    it "creates new build" do
      expect(commit.builds.count(:all)).to eq 2
      commit.retry
      expect(commit.builds.count(:all)).to eq 3
    end
  end

  describe :project_recipients do

    context 'always sending notification' do
      it 'should return commit_pusher_email as only recipient when no additional recipients are given' do
        project = FactoryGirl.create :ci_project,
          email_add_pusher: true,
          email_recipients: ''
        commit =  FactoryGirl.create :ci_commit, project: project
        expected = 'commit_pusher_email'
        allow(commit).to receive(:push_data) { { user_email: expected } }
        expect(commit.project_recipients).to eq([expected])
      end

      it 'should return commit_pusher_email and additional recipients' do
        project = FactoryGirl.create :ci_project,
          email_add_pusher: true,
          email_recipients: 'rec1 rec2'
        commit = FactoryGirl.create :ci_commit, project: project
        expected = 'commit_pusher_email'
        allow(commit).to receive(:push_data) { { user_email: expected } }
        expect(commit.project_recipients).to eq(['rec1', 'rec2', expected])
      end

      it 'should return recipients' do
        project = FactoryGirl.create :ci_project,
          email_add_pusher: false,
          email_recipients: 'rec1 rec2'
        commit = FactoryGirl.create :ci_commit, project: project
        expect(commit.project_recipients).to eq(['rec1', 'rec2'])
      end

      it 'should return unique recipients only' do
        project = FactoryGirl.create :ci_project,
          email_add_pusher: true,
          email_recipients: 'rec1 rec1 rec2'
        commit = FactoryGirl.create :ci_commit, project: project
        expected = 'rec2'
        allow(commit).to receive(:push_data) { { user_email: expected } }
        expect(commit.project_recipients).to eq(['rec1', 'rec2'])
      end
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

  describe :compare? do
    subject { commit_with_project.compare? }

    context 'if commit.before_sha are not nil' do
      it { is_expected.to be_truthy }
    end
  end

  describe :short_sha do
    subject { commit.short_before_sha }

    it 'has 8 items' do
      expect(subject.size).to eq(8)
    end
    it { expect(commit.before_sha).to start_with(subject) }
  end

  describe :short_sha do
    subject { commit.short_sha }

    it 'has 8 items' do
      expect(subject.size).to eq(8)
    end
    it { expect(commit.sha).to start_with(subject) }
  end

  describe :create_next_builds do
    before do
      allow(commit).to receive(:config_processor).and_return(config_processor)
    end

    it "creates builds for next type" do
      expect(commit.create_builds).to be_truthy
      commit.builds.reload
      expect(commit.builds.size).to eq(2)

      expect(commit.create_next_builds(nil)).to be_truthy
      commit.builds.reload
      expect(commit.builds.size).to eq(4)

      expect(commit.create_next_builds(nil)).to be_truthy
      commit.builds.reload
      expect(commit.builds.size).to eq(5)

      expect(commit.create_next_builds(nil)).to be_falsey
    end
  end

  describe :create_builds do
    before do
      allow(commit).to receive(:config_processor).and_return(config_processor)
    end

    it 'creates builds' do
      expect(commit.create_builds).to be_truthy
      commit.builds.reload
      expect(commit.builds.size).to eq(2)
    end

    context 'for build triggers' do
      let(:trigger) { FactoryGirl.create :ci_trigger, project: project }
      let(:trigger_request) { FactoryGirl.create :ci_trigger_request, commit: commit, trigger: trigger }

      it 'creates builds' do
        expect(commit.create_builds(trigger_request)).to be_truthy
        commit.builds.reload
        expect(commit.builds.size).to eq(2)
      end

      it 'rebuilds commit' do
        expect(commit.create_builds).to be_truthy
        commit.builds.reload
        expect(commit.builds.size).to eq(2)

        expect(commit.create_builds(trigger_request)).to be_truthy
        commit.builds.reload
        expect(commit.builds.size).to eq(4)
      end

      it 'creates next builds' do
        expect(commit.create_builds(trigger_request)).to be_truthy
        commit.builds.reload
        expect(commit.builds.size).to eq(2)

        expect(commit.create_next_builds(trigger_request)).to be_truthy
        commit.builds.reload
        expect(commit.builds.size).to eq(4)
      end

      context 'for [ci skip]' do
        before do
          commit.push_data[:commits][0][:message] = 'skip this commit [ci skip]'
          commit.save
        end

        it 'rebuilds commit' do
          expect(commit.status).to eq('skipped')
          expect(commit.create_builds(trigger_request)).to be_truthy
          commit.builds.reload
          expect(commit.builds.size).to eq(2)
          expect(commit.status).to eq('pending')
        end
      end
    end
  end

  describe "#finished_at" do
    let(:project) { FactoryGirl.create :ci_project }
    let(:commit) { FactoryGirl.create :ci_commit, project: project }

    it "returns finished_at of latest build" do
      build = FactoryGirl.create :ci_build, commit: commit, finished_at: Time.now - 60
      build1 = FactoryGirl.create :ci_build, commit: commit, finished_at: Time.now - 120

      expect(commit.finished_at.to_i).to eq(build.finished_at.to_i)
    end

    it "returns nil if there is no finished build" do
      build = FactoryGirl.create :ci_not_started_build, commit: commit

      expect(commit.finished_at).to be_nil
    end
  end

  describe "coverage" do
    let(:project) { FactoryGirl.create :ci_project, coverage_regex: "/.*/" }
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
end
