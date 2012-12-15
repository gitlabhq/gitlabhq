# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  private_flag           :boolean          default(TRUE), not null
#  owner_id               :integer
#  default_branch         :string(255)
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#

require 'spec_helper'

describe Project do
  describe "Associations" do
    it { should belong_to(:group) }
    it { should belong_to(:namespace) }
    it { should belong_to(:owner).class_name('User') }
    it { should have_many(:users) }
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:merge_requests).dependent(:destroy) }
    it { should have_many(:issues).dependent(:destroy) }
    it { should have_many(:milestones).dependent(:destroy) }
    it { should have_many(:users_projects).dependent(:destroy) }
    it { should have_many(:notes).dependent(:destroy) }
    it { should have_many(:snippets).dependent(:destroy) }
    it { should have_many(:deploy_keys).dependent(:destroy) }
    it { should have_many(:hooks).dependent(:destroy) }
    it { should have_many(:wikis).dependent(:destroy) }
    it { should have_many(:protected_branches).dependent(:destroy) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:namespace_id) }
    it { should_not allow_mass_assignment_of(:owner_id) }
    it { should_not allow_mass_assignment_of(:private_flag) }
  end

  describe "Validation" do
    let!(:project) { create(:project) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should ensure_length_of(:name).is_within(0..255) }

    it { should validate_presence_of(:path) }
    it { should validate_uniqueness_of(:path) }
    it { should ensure_length_of(:path).is_within(0..255) }
    # TODO: Formats

    it { should ensure_length_of(:description).is_within(0..2000) }

    # TODO: Formats

    it { should validate_presence_of(:owner) }
    it { should ensure_inclusion_of(:issues_enabled).in_array([true, false]) }
    it { should ensure_inclusion_of(:wall_enabled).in_array([true, false]) }
    it { should ensure_inclusion_of(:merge_requests_enabled).in_array([true, false]) }
    it { should ensure_inclusion_of(:wiki_enabled).in_array([true, false]) }

    it "should not allow new projects beyond user limits" do
      project.stub(:owner).and_return(double(can_create_project?: false, projects_limit: 1))
      project.should_not be_valid
      project.errors[:base].first.should match(/Your own projects limit is 1/)
    end

    it "should not allow 'gitolite-admin' as repo name" do
      should allow_value("blah").for(:path)
      should_not allow_value("gitolite-admin").for(:path)
    end
  end

  describe "Respond to" do
    it { should respond_to(:public?) }
    it { should respond_to(:private?) }
    it { should respond_to(:url_to_repo) }
    it { should respond_to(:path_to_repo) }
    it { should respond_to(:valid_repo?) }
    it { should respond_to(:repo_exists?) }

    # Repository Role
    it { should respond_to(:tree) }
    it { should respond_to(:root_ref) }
    it { should respond_to(:repo) }
    it { should respond_to(:tags) }
    it { should respond_to(:commit) }
    it { should respond_to(:commits) }
    it { should respond_to(:commits_between) }
    it { should respond_to(:commits_with_refs) }
    it { should respond_to(:commits_since) }
    it { should respond_to(:commits_between) }
    it { should respond_to(:satellite) }
    it { should respond_to(:update_repository) }
    it { should respond_to(:destroy_repository) }
    it { should respond_to(:archive_repo) }

    # Authority Role
    it { should respond_to(:add_access) }
    it { should respond_to(:reset_access) }
    it { should respond_to(:repository_writers) }
    it { should respond_to(:repository_masters) }
    it { should respond_to(:repository_readers) }
    it { should respond_to(:allow_read_for?) }
    it { should respond_to(:guest_access_for?) }
    it { should respond_to(:report_access_for?) }
    it { should respond_to(:dev_access_for?) }
    it { should respond_to(:master_access_for?) }

    # Team Role
    it { should respond_to(:team_member_by_name_or_email) }
    it { should respond_to(:team_member_by_id) }
    it { should respond_to(:add_user_to_team) }
    it { should respond_to(:add_users_to_team) }
    it { should respond_to(:add_user_id_to_team) }
    it { should respond_to(:add_users_ids_to_team) }

    # Project Push Role
    it { should respond_to(:observe_push) }
    it { should respond_to(:update_merge_requests) }
    it { should respond_to(:execute_hooks) }
    it { should respond_to(:post_receive_data) }
    it { should respond_to(:trigger_post_receive) }

    # Namespaced Project Role
    it { should respond_to(:transfer) }
    it { should respond_to(:name_with_namespace) }
    it { should respond_to(:namespace_owner) }
    it { should respond_to(:chief) }
    it { should respond_to(:path_with_namespace) }
  end

  describe 'modules' do
    it { should include_module(Repository) }
    it { should include_module(PushObserver) }
    it { should include_module(Authority) }
    it { should include_module(Team) }
    it { should include_module(NamespacedProject) }
  end

  it "should return valid url to repo" do
    project = Project.new(path: "somewhere")
    project.url_to_repo.should == Gitlab.config.gitolite.ssh_path_prefix + "somewhere.git"
  end

  it "should return path to repo" do
    project = Project.new(path: "somewhere")
    project.path_to_repo.should == Rails.root.join("tmp", "repositories", "somewhere")
  end

  it "returns the full web URL for this repo" do
    project = Project.new(path: "somewhere")
    project.web_url.should == "#{Gitlab.config.gitlab.url}/somewhere"
  end

  describe "last_activity methods" do
    let(:project)    { create(:project) }
    let(:last_event) { double(created_at: Time.now) }

    describe "last_activity" do
      it "should alias last_activity to last_event"do
        project.stub(last_event: last_event)
        project.last_activity.should == last_event
      end
    end

    describe 'last_activity_date' do
      it 'returns the creation date of the project\'s last event if present' do
        project.stub(last_event: last_event)
        project.last_activity_date.should == last_event.created_at
      end

      it 'returns the project\'s last update date if it has no events' do
        project.last_activity_date.should == project.updated_at
      end
    end
  end

  describe :update_merge_requests do
    let(:project) { create(:project) }

    before do
      @merge_request = create(:merge_request,
                              project: project,
                              merged: false,
                              closed: false)
      @key = create(:key, user_id: project.owner.id)
    end

    it "should close merge request if last commit from source branch was pushed to target branch" do
      @merge_request.reloaded_commits
      @merge_request.last_commit.id.should == "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
      project.update_merge_requests("8716fc78f3c65bbf7bcf7b574febd583bc5d2812", "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a", "refs/heads/stable", @key.user)
      @merge_request.reload
      @merge_request.merged.should be_true
      @merge_request.closed.should be_true
    end

    it "should update merge request commits with new one if pushed to source branch" do
      @merge_request.last_commit.should == nil
      project.update_merge_requests("8716fc78f3c65bbf7bcf7b574febd583bc5d2812", "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a", "refs/heads/master", @key.user)
      @merge_request.reload
      @merge_request.last_commit.id.should == "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a"
    end
  end
end
