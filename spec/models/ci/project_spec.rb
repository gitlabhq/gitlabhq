# == Schema Information
#
# Table name: ci_projects
#
#  id                       :integer          not null, primary key
#  name                     :string(255)
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
  let(:project) { FactoryGirl.create :ci_project }
  let(:gl_project) { project.gl_project }
  subject { project }

  it { is_expected.to have_many(:runner_projects) }
  it { is_expected.to have_many(:runners) }
  it { is_expected.to have_many(:web_hooks) }
  it { is_expected.to have_many(:events) }
  it { is_expected.to have_many(:variables) }
  it { is_expected.to have_many(:triggers) }
  it { is_expected.to have_many(:services) }

  it { is_expected.to validate_presence_of :timeout }
  it { is_expected.to validate_presence_of :gitlab_id }

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

  describe :name_with_namespace do
    subject { project.name_with_namespace }

    it { is_expected.to eq(project.name) }
    it { is_expected.to eq(gl_project.name_with_namespace) }
  end

  describe :path_with_namespace do
    subject { project.path_with_namespace }

    it { is_expected.to eq(project.path) }
    it { is_expected.to eq(gl_project.path_with_namespace) }
  end

  describe :path_with_namespace do
    subject { project.web_url }

    it { is_expected.to eq(gl_project.web_url) }
  end

  describe :web_url do
    subject { project.web_url }

    it { is_expected.to eq(project.gitlab_url) }
    it { is_expected.to eq(gl_project.web_url) }
  end

  describe :http_url_to_repo do
    subject { project.http_url_to_repo }

    it { is_expected.to eq(gl_project.http_url_to_repo) }
  end

  describe :ssh_url_to_repo do
    subject { project.ssh_url_to_repo }

    it { is_expected.to eq(gl_project.ssh_url_to_repo) }
  end

  describe :commits do
    subject { project.commits }

    before do
      FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, gl_project: gl_project
    end

    it { is_expected.to eq(gl_project.ci_commits) }
  end

  describe :builds do
    subject { project.builds }

    before do
      commit = FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, gl_project: gl_project
      FactoryGirl.create :ci_build, commit: commit
    end

    it { is_expected.to eq(gl_project.ci_builds) }
  end

  describe "ordered_by_last_commit_date" do
    it "returns ordered projects" do
      newest_project = FactoryGirl.create :empty_project
      newest_ci_project = newest_project.ensure_gitlab_ci_project
      oldest_project = FactoryGirl.create :empty_project
      oldest_ci_project = oldest_project.ensure_gitlab_ci_project
      project_without_commits = FactoryGirl.create :empty_project
      ci_project_without_commits = project_without_commits.ensure_gitlab_ci_project

      FactoryGirl.create :ci_commit, committed_at: 1.hour.ago, gl_project: newest_project
      FactoryGirl.create :ci_commit, committed_at: 2.hour.ago, gl_project: oldest_project

      expect(Ci::Project.ordered_by_last_commit_date).to eq([newest_ci_project, oldest_ci_project, ci_project_without_commits])
    end
  end

  context :valid_project do
    let(:commit) { FactoryGirl.create(:ci_commit) }

    context :project_with_commit_and_builds do
      let(:project) { commit.project }

      before do
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

    it "checks the presence of specific runner" do
      project = FactoryGirl.create(:ci_project)
      specific_runner = FactoryGirl.create(:ci_specific_runner)
      project.runners << specific_runner
      expect(project.any_runners? { |runner| runner == specific_runner }).to be_truthy
    end

    it "checks the presence of shared runner" do
      project = FactoryGirl.create(:ci_project, shared_runners_enabled: true)
      shared_runner = FactoryGirl.create(:ci_shared_runner)
      expect(project.any_runners? { |runner| runner == shared_runner }).to be_truthy
    end
  end
end
