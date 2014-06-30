# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  last_activity_at       :datetime
#  import_url             :string(255)
#  visibility_level       :integer          default(0), not null
#  archived               :boolean          default(FALSE), not null
#  import_status          :string(255)
#

require 'spec_helper'

describe Project do
  describe "Associations" do
    it { should belong_to(:group) }
    it { should belong_to(:namespace) }
    it { should belong_to(:creator).class_name('User') }
    it { should have_many(:users) }
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:merge_requests).dependent(:destroy) }
    it { should have_many(:issues).dependent(:destroy) }
    it { should have_many(:milestones).dependent(:destroy) }
    it { should have_many(:users_projects).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_many(:snippets).class_name('ProjectSnippet').dependent(:destroy) }
    it { should have_many(:deploy_keys_projects).dependent(:destroy) }
    it { should have_many(:deploy_keys) }
    it { should have_many(:hooks).dependent(:destroy) }
    it { should have_many(:protected_branches).dependent(:destroy) }
    it { should have_one(:forked_project_link).dependent(:destroy) }
    it { should have_one(:slack_service).dependent(:destroy) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:namespace_id) }
    it { should_not allow_mass_assignment_of(:creator_id) }
  end

  describe "Validation" do
    let!(:project) { create(:project) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:namespace_id) }
    it { should ensure_length_of(:name).is_within(0..255) }

    it { should validate_presence_of(:path) }
    it { should validate_uniqueness_of(:path).scoped_to(:namespace_id) }
    it { should ensure_length_of(:path).is_within(0..255) }
    it { should ensure_length_of(:description).is_within(0..2000) }
    it { should validate_presence_of(:creator) }
    it { should ensure_length_of(:issues_tracker_id).is_within(0..255) }
    it { should validate_presence_of(:namespace) }

    it "should not allow new projects beyond user limits" do
      project2 = build(:project)
      allow(project2).to receive(:creator).and_return(double(can_create_project?: false, projects_limit: 0).as_null_object)
      expect(project2).not_to be_valid
      expect(project2.errors[:limit_reached].first).to match(/Your project limit is 0/)
    end
  end

  describe "Respond to" do
    it { should respond_to(:url_to_repo) }
    it { should respond_to(:repo_exists?) }
    it { should respond_to(:satellite) }
    it { should respond_to(:update_merge_requests) }
    it { should respond_to(:execute_hooks) }
    it { should respond_to(:name_with_namespace) }
    it { should respond_to(:owner) }
    it { should respond_to(:path_with_namespace) }
  end

  it "should return valid url to repo" do
    project = Project.new(path: "somewhere")
    expect(project.url_to_repo).to eq(Gitlab.config.gitlab_shell.ssh_path_prefix + "somewhere.git")
  end

  it "returns the full web URL for this repo" do
    project = Project.new(path: "somewhere")
    expect(project.web_url).to eq("#{Gitlab.config.gitlab.url}/somewhere")
  end

  it "returns the web URL without the protocol for this repo" do
    project = Project.new(path: "somewhere")
    expect(project.web_url_without_protocol).to eq("#{Gitlab.config.gitlab.url.split("://")[1]}/somewhere")
  end

  describe "last_activity methods" do
    let(:project) { create(:project) }
    let(:last_event) { double(created_at: Time.now) }

    describe "last_activity" do
      it "should alias last_activity to last_event" do
        project.stub(last_event: last_event)
        expect(project.last_activity).to eq(last_event)
      end
    end

    describe 'last_activity_date' do
      it 'returns the creation date of the project\'s last event if present' do
        last_activity_event = create(:event, project: project)
        expect(project.last_activity_at.to_i).to eq(last_event.created_at.to_i)
      end

      it 'returns the project\'s last update date if it has no events' do
        expect(project.last_activity_date).to eq(project.updated_at)
      end
    end
  end

  describe :update_merge_requests do
    let(:project) { create(:project) }

    before do
      @merge_request = create(:merge_request, source_project: project, target_project: project)
      @key = create(:key, user_id: project.owner.id)
    end

    it "should close merge request if last commit from source branch was pushed to target branch" do
      @merge_request.reload_code
      expect(@merge_request.last_commit.id).to eq("69b34b7e9ad9f496f0ad10250be37d6265a03bba")
      project.update_merge_requests("8716fc78f3c65bbf7bcf7b574febd583bc5d2812", "69b34b7e9ad9f496f0ad10250be37d6265a03bba", "refs/heads/stable", @key.user)
      @merge_request.reload
      expect(@merge_request.merged?).to be_true
    end

    it "should update merge request commits with new one if pushed to source branch" do
      project.update_merge_requests("8716fc78f3c65bbf7bcf7b574febd583bc5d2812", "69b34b7e9ad9f496f0ad10250be37d6265a03bba", "refs/heads/master", @key.user)
      @merge_request.reload
      expect(@merge_request.last_commit.id).to eq("69b34b7e9ad9f496f0ad10250be37d6265a03bba")
    end
  end


  describe :find_with_namespace do
    context 'with namespace' do
      before do
        @group = create :group, name: 'gitlab'
        @project = create(:project, name: 'gitlabhq', namespace: @group)
      end

      it { expect(Project.find_with_namespace('gitlab/gitlabhq')).to eq(@project) }
      it { expect(Project.find_with_namespace('gitlab-ci')).to be_nil }
    end
  end

  describe :to_param do
    context 'with namespace' do
      before do
        @group = create :group, name: 'gitlab'
        @project = create(:project, name: 'gitlabhq', namespace: @group)
      end

      it { expect(@project.to_param).to eq("gitlab/gitlabhq") }
    end
  end

  describe :repository do
    let(:project) { create(:project) }

    it "should return valid repo" do
      expect(project.repository).to be_kind_of(Repository)
    end
  end

  describe :issue_exists? do
    let(:project) { create(:project) }
    let(:existed_issue) { create(:issue, project: project) }
    let(:not_existed_issue) { create(:issue) }
    let(:ext_project) { create(:redmine_project) }

    it "should be true or if used internal tracker and issue exists" do
      expect(project.issue_exists?(existed_issue.iid)).to be_true
    end

    it "should be false or if used internal tracker and issue not exists" do
      expect(project.issue_exists?(not_existed_issue.iid)).to be_false
    end

    it "should always be true if used other tracker" do
      expect(ext_project.issue_exists?(rand(100))).to be_true
    end
  end

  describe :used_default_issues_tracker? do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    it "should be true if used internal tracker" do
      expect(project.used_default_issues_tracker?).to be_true
    end

    it "should be false if used other tracker" do
      expect(ext_project.used_default_issues_tracker?).to be_false
    end
  end

  describe :can_have_issues_tracker_id? do
    let(:project) { create(:project) }
    let(:ext_project) { create(:redmine_project) }

    it "should be true for projects with external issues tracker if issues enabled" do
      expect(ext_project.can_have_issues_tracker_id?).to be_true
    end

    it "should be false for projects with internal issue tracker if issues enabled" do
      expect(project.can_have_issues_tracker_id?).to be_false
    end

    it "should be always false if issues disabled" do
      project.issues_enabled = false
      ext_project.issues_enabled = false

      expect(project.can_have_issues_tracker_id?).to be_false
      expect(ext_project.can_have_issues_tracker_id?).to be_false
    end
  end

  describe :open_branches do
    let(:project) { create(:project) }

    before do
      project.protected_branches.create(name: 'master')
    end

    it { expect(project.open_branches.map(&:name)).to include('bootstrap') }
    it { expect(project.open_branches.map(&:name)).not_to include('master') }
  end
end
