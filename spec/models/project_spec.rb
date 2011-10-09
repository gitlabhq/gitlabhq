require 'spec_helper'

describe Project do
  describe "Associations" do
    it { should have_many(:users) }
    it { should have_many(:users_projects) }
  end

  describe "Validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:path) }
  end

  describe "Respond to" do
    it { should respond_to(:readers) }
    it { should respond_to(:writers) }
    it { should respond_to(:gitosis_writers) }
    it { should respond_to(:admins) }
    it { should respond_to(:add_access) }
    it { should respond_to(:reset_access) }
    it { should respond_to(:update_gitosis_project) }
    it { should respond_to(:destroy_gitosis_project) }
    it { should respond_to(:public?) }
    it { should respond_to(:private?) }
    it { should respond_to(:url_to_repo) }
    it { should respond_to(:path_to_repo) }
    it { should respond_to(:valid_repo?) }
    it { should respond_to(:repo_exists?) }
    it { should respond_to(:repo) }
    it { should respond_to(:tags) }
    it { should respond_to(:commit) }
  end

  it "should return valid url to repo" do 
    project = Project.new(:path => "somewhere")
    project.url_to_repo.should == "git@localhost:somewhere.git"
  end

  it "should return path to repo" do 
    project = Project.new(:path => "somewhere")
    project.path_to_repo.should == "/tmp/somewhere"
  end

  describe :valid_repo? do 
    it "should be valid repo" do 
      project = Factory :project
      project.valid_repo?.should be_true 
    end

    it "should be invalid repo" do
      project = Project.new(:name => "ok_name", :path => "/INVALID_PATH/", :code => "NEOK")
      project.valid_repo?.should be_false
    end
  end

  describe "Git methods" do 
    let(:project) { Factory :project }

    describe :repo do 
      it "should return valid repo" do 
        project.repo.should be_kind_of(Grit::Repo)
      end

      it "should return nil" do 
        lambda { Project.new(:path => "invalid").repo }.should raise_error(Grit::NoSuchPathError)
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
end
# == Schema Information
#
# Table name: projects
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  path         :string(255)
#  description  :text
#  created_at   :datetime
#  updated_at   :datetime
#  private_flag :boolean         default(TRUE), not null
#  code         :string(255)
#  owner_id     :integer
#

