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

describe Project do
  subject { FactoryGirl.build :project }

  it { should have_many(:commits) }

  it { should validate_presence_of :name }
  it { should validate_presence_of :timeout }
  it { should validate_presence_of :default_ref }

  describe 'before_validation' do
    it 'should set an random token if none provided' do
      project = FactoryGirl.create :project_without_token
      project.token.should_not == ""
    end

    it 'should not set an random toke if one provided' do
      project = FactoryGirl.create :project
      project.token.should == "iPWx6WM4lhHNedGfBpPJNP"
    end
  end

  describe "ordered_by_last_commit_date" do
    it "returns ordered projects" do
      newest_project = FactoryGirl.create :project
      oldest_project = FactoryGirl.create :project
      project_without_commits = FactoryGirl.create :project

      FactoryGirl.create :commit, committed_at: 1.hour.ago, project: newest_project
      FactoryGirl.create :commit, committed_at: 2.hour.ago, project: oldest_project

      Project.ordered_by_last_commit_date.should == [newest_project, oldest_project, project_without_commits]
    end
  end

  context :valid_project do
    let(:project) { FactoryGirl.create :project }

    context :project_with_commit_and_builds do
      before do
        commit = FactoryGirl.create(:commit, project: project)
        FactoryGirl.create(:build, commit: commit)
      end

      it { project.status.should == 'pending' }
      it { project.last_commit.should be_kind_of(Commit)  }
      it { project.human_status.should == 'pending' }
    end
  end

  describe '#email_notification?' do
    it do
      project = FactoryGirl.create :project, email_add_pusher: true
      project.email_notification?.should == true
    end

    it do
      project = FactoryGirl.create :project, email_add_pusher: false, email_recipients: 'test tesft'
      project.email_notification?.should == true
    end

    it do
      project = FactoryGirl.create :project, email_add_pusher: false, email_recipients: ''
      project.email_notification?.should == false
    end
  end

  describe '#broken_or_success?' do
    it {
      project = FactoryGirl.create :project, email_add_pusher: true
      project.stub(:broken?).and_return(true)
      project.stub(:success?).and_return(true)
      project.broken_or_success?.should == true
    }

    it {
      project = FactoryGirl.create :project, email_add_pusher: true
      project.stub(:broken?).and_return(true)
      project.stub(:success?).and_return(false)
      project.broken_or_success?.should == true
    }

    it {
      project = FactoryGirl.create :project, email_add_pusher: true
      project.stub(:broken?).and_return(false)
      project.stub(:success?).and_return(true)
      project.broken_or_success?.should == true
    }

    it {
      project = FactoryGirl.create :project, email_add_pusher: true
      project.stub(:broken?).and_return(false)
      project.stub(:success?).and_return(false)
      project.broken_or_success?.should == false
    }
  end

  describe 'Project.parse' do
    let(:project_dump) { YAML.load File.read(Rails.root.join('spec/support/gitlab_stubs/raw_project.yml')) }
    let(:parsed_project) { Project.parse(project_dump) }

    
    it { parsed_project.should be_valid }
    it { parsed_project.should be_kind_of(Project) }
    it { parsed_project.name.should eq("GitLab / api.gitlab.org") }
    it { parsed_project.gitlab_id.should eq(189) }
    it { parsed_project.gitlab_url.should eq("http://demo.gitlab.com/gitlab/api-gitlab-org") }

    it "parses plain hash" do
      Project.parse(project_dump).name.should eq("GitLab / api.gitlab.org")
    end
  end

  describe :repo_url_with_auth do
    let(:project) { FactoryGirl.create :project }
    subject { project.repo_url_with_auth }

    it { should be_a(String) }
    it { should end_with(".git") }
    it { should start_with(project.gitlab_url[0..6]) }
    it { should include(project.token) }
    it { should include('gitlab-ci-token') }
    it { should include(project.gitlab_url[7..-1]) }
  end

  describe :search do
    let!(:project) { FactoryGirl.create(:project, name: "foo") }

    it { Project.search('fo').should include(project) }
    it { Project.search('bar').should be_empty }
  end

  describe :any_runners do
    it "there are no runners available" do
      project = FactoryGirl.create(:project)
      project.any_runners?.should be_false
    end

    it "there is a specific runner" do
      project = FactoryGirl.create(:project)
      project.runners << FactoryGirl.create(:specific_runner)
      project.any_runners?.should be_true
    end

    it "there is a shared runner" do
      project = FactoryGirl.create(:project, shared_runners_enabled: true)
      FactoryGirl.create(:shared_runner)
      project.any_runners?.should be_true
    end

    it "there is a shared runner, but they are prohibited to use" do
      project = FactoryGirl.create(:project)
      FactoryGirl.create(:shared_runner)
      project.any_runners?.should be_false
    end
  end
end
