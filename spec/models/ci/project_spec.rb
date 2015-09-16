# == Schema Information
#
# Table name: projects
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  timeout                  :integer          default(3600), not null
#  created_at               :datetime
#  updated_at               :datetime
#  token                    :string(255)
#  default_ref              :string(255)
#  path                     :string(255)
#  always_build             :boolean          default(FALSE), not null
#  polling_interval         :integer
#  public                   :boolean          default(FALSE), not null
#  ssh_url_to_repo          :string(255)
#  gitlab_id                :integer
#  allow_git_fetch          :boolean          default(TRUE), not null
#  email_recipients         :string(255)      default(""), not null
#  email_add_pusher         :boolean          default(TRUE), not null
#  email_only_broken_builds :boolean          default(TRUE), not null
#  skip_refs                :string(255)
#  coverage_regex           :string(255)
#  shared_runners_enabled   :boolean          default(FALSE)
#  generated_yaml_config    :text
#

require 'spec_helper'

describe Ci::Project do
  subject { FactoryGirl.build :ci_project }

  it { is_expected.to have_many(:commits) }

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_presence_of :timeout }
  it { is_expected.to validate_presence_of :default_ref }

  describe 'before_validation' do
    it 'should set an random token if none provided' do
      project = FactoryGirl.create :ci_project_without_token
      expect(project.token).not_to eq("")
    end

    it 'should not set an random toke if one provided' do
      project = FactoryGirl.create :ci_project
      expect(project.token).to eq("iPWx6WM4lhHNedGfBpPJNP")
    end
  end

  describe "ordered_by_last_commit_date" do
    it "returns ordered projects" do
      newest_project = FactoryGirl.create :ci_project
      oldest_project = FactoryGirl.create :ci_project
      project_without_commits = FactoryGirl.create :ci_project

      FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, project: newest_project
      FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, project: oldest_project

      expect(Ci::Project.ordered_by_last_commit_date).to eq([newest_project, oldest_project, project_without_commits])
    end
  end

  describe 'ordered commits' do
    let(:project) { FactoryGirl.create :ci_project }

    it 'returns ordered list of commits' do
      commit1 = FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, project: project
      commit2 = FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, project: project
      expect(project.commits).to eq([commit2, commit1])
    end

    it 'returns commits ordered by committed_at and id, with nulls last' do
      commit1 = FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, project: project
      commit2 = FactoryGirl.create :ci_commit, committed_at: nil, project: project
      commit3 = FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, project: project
      commit4 = FactoryGirl.create :ci_commit, committed_at: nil, project: project
      expect(project.commits).to eq([commit2, commit4, commit3, commit1])
    end
  end

  context :valid_project do
    let(:project) { FactoryGirl.create :ci_project }

    context :project_with_commit_and_builds do
      before do
        commit = FactoryGirl.create(:ci_commit, project: project)
        FactoryGirl.create(:ci_build, commit: commit)
      end

      it { expect(project.status).to eq('pending') }
      it { expect(project.last_commit).to be_kind_of(Ci::Commit)  }
      it { expect(project.human_status).to eq('pending') }
    end
  end

  describe '#email_notification?' do
    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: true
      expect(project.email_notification?).to eq(true)
    end

    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: false, email_recipients: 'test tesft'
      expect(project.email_notification?).to eq(true)
    end

    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: false, email_recipients: ''
      expect(project.email_notification?).to eq(false)
    end
  end

  describe '#broken_or_success?' do
    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: true
      allow(project).to receive(:broken?).and_return(true)
      allow(project).to receive(:success?).and_return(true)
      expect(project.broken_or_success?).to eq(true)
    end

    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: true
      allow(project).to receive(:broken?).and_return(true)
      allow(project).to receive(:success?).and_return(false)
      expect(project.broken_or_success?).to eq(true)
    end

    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: true
      allow(project).to receive(:broken?).and_return(false)
      allow(project).to receive(:success?).and_return(true)
      expect(project.broken_or_success?).to eq(true)
    end

    it do
      project = FactoryGirl.create :ci_project, email_add_pusher: true
      allow(project).to receive(:broken?).and_return(false)
      allow(project).to receive(:success?).and_return(false)
      expect(project.broken_or_success?).to eq(false)
    end
  end

  describe 'Project.parse' do
    let(:project) { FactoryGirl.create :project }

    subject { Ci::Project.parse(project) }

    it { is_expected.to be_valid }
    it { is_expected.to be_kind_of(Ci::Project) }
    it { expect(subject.name).to eq(project.name_with_namespace) }
    it { expect(subject.gitlab_id).to eq(project.id) }
    it { expect(subject.gitlab_url).to eq(project.web_url) }
  end

  describe :repo_url_with_auth do
    let(:project) { FactoryGirl.create :ci_project }
    subject { project.repo_url_with_auth }

    it { is_expected.to be_a(String) }
    it { is_expected.to end_with(".git") }
    it { is_expected.to start_with(project.gitlab_url[0..6]) }
    it { is_expected.to include(project.token) }
    it { is_expected.to include('gitlab-ci-token') }
    it { is_expected.to include(project.gitlab_url[7..-1]) }
  end

  describe :search do
    let!(:project) { FactoryGirl.create(:ci_project, name: "foo") }

    it { expect(Ci::Project.search('fo')).to include(project) }
    it { expect(Ci::Project.search('bar')).to be_empty }
  end

  describe :any_runners do
    it "there are no runners available" do
      project = FactoryGirl.create(:ci_project)
      expect(project.any_runners?).to be_falsey
    end

    it "there is a specific runner" do
      project = FactoryGirl.create(:ci_project)
      project.runners << FactoryGirl.create(:ci_specific_runner)
      expect(project.any_runners?).to be_truthy
    end

    it "there is a shared runner" do
      project = FactoryGirl.create(:ci_project, shared_runners_enabled: true)
      FactoryGirl.create(:ci_shared_runner)
      expect(project.any_runners?).to be_truthy
    end

    it "there is a shared runner, but they are prohibited to use" do
      project = FactoryGirl.create(:ci_project)
      FactoryGirl.create(:ci_shared_runner)
      expect(project.any_runners?).to be_falsey
    end
  end
end
