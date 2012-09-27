require 'spec_helper'

describe Project do
  describe "Associations" do
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

    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code) }
    it { should ensure_length_of(:code).is_within(1..255) }
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
  end

  describe 'modules' do
    it { should include_module(Repository) }
    it { should include_module(PushObserver) }
    it { should include_module(Authority) }
    it { should include_module(Team) }
  end

  it "should return valid url to repo" do
    project = Project.new(path: "somewhere")
    project.url_to_repo.should == Gitlab.config.ssh_path + "somewhere.git"
  end

  it "should return path to repo" do
    project = Project.new(path: "somewhere")
    project.path_to_repo.should == Rails.root.join("tmp", "repositories", "somewhere")
  end

  it "returns the full web URL for this repo" do
    project = Project.new(code: "somewhere")
    project.web_url.should == "#{Gitlab.config.url}/somewhere"
  end

  describe :valid_repo? do
    it "should be valid repo" do
      project = Factory :project
      project.valid_repo?.should be_true
    end

    it "should be invalid repo" do
      project = Project.new(name: "ok_name", path: "/INVALID_PATH/", code: "NEOK")
      project.valid_repo?.should be_false
    end
  end

  describe "last_activity" do
    let(:project)    { Factory :project }
    let(:last_event) { double }

    before do
      project.stub_chain(:events, :order).and_return( [ double, double, last_event ] )
    end

    it { project.last_activity.should == last_event }
  end

  describe 'last_activity_date' do
    let(:project)    { Factory :project }

    it 'returns the creation date of the project\'s last event if present' do
      last_event = double(created_at: 'now')
      project.stub(:events).and_return( [double, double, last_event] )
      project.last_activity_date.should == last_event.created_at
    end

    it 'returns the project\'s last update date if it has no events' do
      project.last_activity_date.should == project.updated_at
    end
  end
  describe "fresh commits" do
    let(:project) { Factory :project }

    it { project.fresh_commits(3).count.should == 3 }
    it { project.fresh_commits.first.id.should == "bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a" }
    it { project.fresh_commits.last.id.should == "f403da73f5e62794a0447aca879360494b08f678" }
  end

  describe "commits_between" do
    let(:project) { Factory :project }

    subject do
      commits = project.commits_between("3a4b4fb4cde7809f033822a171b9feae19d41fff",
                                        "8470d70da67355c9c009e4401746b1d5410af2e3")
      commits.map { |c| c.id }
    end

    it { should have(3).elements }
    it { should include("f0f14c8eaba69ebddd766498a9d0b0e79becd633") }
    it { should_not include("bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a") }
  end

  describe "Git methods" do
    let(:project) { Factory :project }

    describe :repo do
      it "should return valid repo" do
        project.repo.should be_kind_of(Grit::Repo)
      end

      it "should return nil" do
        lambda { Project.new(path: "invalid").repo }.should raise_error(Grit::NoSuchPathError)
      end

      it "should return nil" do
        lambda { Project.new.repo }.should raise_error(TypeError)
      end
    end

    describe :commit do
      it "should return first head commit if without params" do
        project.commit.id.should == project.repo.commits.first.id
      end

      it "should return valid commit" do
        project.commit(ValidCommit::ID).should be_valid_commit
      end

      it "should return nil" do
        project.commit("+123_4532530XYZ").should be_nil
      end
    end

    describe :tree do
      before do
        @commit = project.commit(ValidCommit::ID)
      end

      it "should raise error w/o arguments" do
        lambda { project.tree }.should raise_error
      end

      it "should return root tree for commit" do
        tree = project.tree(@commit)
        tree.contents.size.should == ValidCommit::FILES_COUNT
        tree.contents.map(&:name).should == ValidCommit::FILES
      end

      it "should return root tree for commit with correct path" do
        tree = project.tree(@commit, ValidCommit::C_FILE_PATH)
        tree.contents.map(&:name).should == ValidCommit::C_FILES
      end

      it "should return root tree for commit with incorrect path" do
        project.tree(@commit, "invalid_path").should be_nil
      end
    end
  end

  describe :update_merge_requests do
    let(:project) { Factory :project }

    before do
      @merge_request = Factory :merge_request,
        project: project,
        merged: false,
        closed: false
      @key = Factory :key, user_id: project.owner.id
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
