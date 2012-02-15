require 'spec_helper'

describe Project do
  describe "Associations" do
    it { should have_many(:users) }
    it { should have_many(:users_projects) }
    it { should have_many(:issues) }
    it { should have_many(:notes) }
    it { should have_many(:snippets) }
    it { should have_many(:web_hooks).dependent(:destroy) }
  end

  describe "Validation" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:path) }
    it { should validate_presence_of(:code) }
  end

  describe "Respond to" do
    it { should respond_to(:readers) }
    it { should respond_to(:writers) }
    it { should respond_to(:repository_writers) }
    it { should respond_to(:admins) }
    it { should respond_to(:add_access) }
    it { should respond_to(:reset_access) }
    it { should respond_to(:update_repository) }
    it { should respond_to(:destroy_repository) }
    it { should respond_to(:public?) }
    it { should respond_to(:private?) }
    it { should respond_to(:url_to_repo) }
    it { should respond_to(:path_to_repo) }
    it { should respond_to(:valid_repo?) }
    it { should respond_to(:repo_exists?) }
    it { should respond_to(:repo) }
    it { should respond_to(:tags) }
    it { should respond_to(:commit) }
    it { should respond_to(:commits_between) }
  end

  it "should not allow 'gitolite-admin' as repo name" do
    should allow_value("blah").for(:path)
    should_not allow_value("gitolite-admin").for(:path)
  end

  it "should return valid url to repo" do
    project = Project.new(:path => "somewhere")
    project.url_to_repo.should == "git@localhost:somewhere.git"
  end

  it "should return path to repo" do
    project = Project.new(:path => "somewhere")
    project.path_to_repo.should == File.join(Rails.root, "tmp", "tests", "somewhere")
  end

  it "returns the full web URL for this repo" do
    project = Project.new(:code => "somewhere")
    project.web_url.should == "#{GIT_HOST['host']}/somewhere"
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

  describe "web hooks" do
    let(:project) { Factory :project }

    context "with no web hooks" do
      it "raises no errors" do
        lambda {
          project.execute_web_hooks('oldrev', 'newrev', 'ref')
        }.should_not raise_error
      end
    end

    context "with web hooks" do
      before do
        @webhook = Factory(:web_hook)
        @webhook_2 = Factory(:web_hook)
        project.web_hooks << [@webhook, @webhook_2]
      end

      it "executes multiple web hook" do
        @webhook.should_receive(:execute).once
        @webhook_2.should_receive(:execute).once

        project.execute_web_hooks('oldrev', 'newrev', 'refs/heads/master')
      end
    end

    context "does not execute web hooks" do
      before do
        @webhook = Factory(:web_hook)
        project.web_hooks << [@webhook]
      end

      it "when pushing a branch for the first time" do
        @webhook.should_not_receive(:execute)
        project.execute_web_hooks('00000000000000000000000000000000', 'newrev', 'refs/heads/master')
      end

      it "when pushing tags" do
        @webhook.should_not_receive(:execute)
        project.execute_web_hooks('oldrev', 'newrev', 'refs/tags/v1.0.0')
      end
    end

    context "when pushing new branches" do

    end

    context "when gathering commit data" do
      before do
        @oldrev, @newrev, @ref = project.fresh_commits(2).last.sha, project.fresh_commits(2).first.sha, 'refs/heads/master'
        @commit = project.fresh_commits(2).first

        # Fill nil/empty attributes
        project.description = "This is a description"

        @data = project.web_hook_data(@oldrev, @newrev, @ref)
      end

      subject { @data }

      it { should include(before: @oldrev) }
      it { should include(after: @newrev) }
      it { should include(ref: @ref) }

      context "with repository data" do
        subject { @data[:repository] }

        it { should include(name: project.name) }
        it { should include(url: project.web_url) }
        it { should include(description: project.description) }
        it { should include(homepage: project.web_url) }
        it { should include(private: project.private?) }
      end

      context "with commits" do
        subject { @data[:commits] }

        it { should be_an(Array) }
        it { should have(1).element }

        context "the commit" do
          subject { @data[:commits].first }

          it { should include(id: @commit.id) }
          it { should include(message: @commit.safe_message) }
          it { should include(timestamp: @commit.date.xmlschema) }
          it { should include(url: "http://localhost/#{project.code}/commits/#{@commit.id}") }

          context "with a author" do
            subject { @data[:commits].first[:author] }

            it { should include(name: @commit.author_name) }
            it { should include(email: @commit.author_email) }
          end
        end
      end

    end
  end

  describe "updates" do
    let(:project) { Factory :project }

    before do
      @issue = Factory :issue,
        :project => project,
        :author => Factory(:user),
        :assignee => Factory(:user)

      @note = Factory :note,
        :project => project,
        :author => Factory(:user)

      @commit = project.fresh_commits(1).first
    end

    describe "return commit, note & issue" do
      it { project.updates(3).count.should == 3 }
      it { project.updates(3).last.id.should == @commit.id }
      it { project.updates(3).include?(@issue).should be_true }
      it { project.updates(3).include?(@note).should be_true }
    end
  end

  describe "last_activity" do
    let(:project) { Factory :project }

    before do
      @note = Factory :note,
        :project => project,
        :author => Factory(:user)
    end

    it { project.last_activity.should == @note }
    it { project.last_activity_date.to_s.should == @note.created_at.to_s }
  end

  describe "fresh commits" do
    let(:project) { Factory :project }

    it { project.fresh_commits(3).count.should == 3 }
    it { project.fresh_commits.first.id.should == "2fb376f61875b58bceee0492e270e9c805294b1a" }
    it { project.fresh_commits.last.id.should == "0dac878dbfe0b9c6104a87d65fe999149a8d862c" }
  end

  describe "commits_between" do
    let(:project) { Factory :project }

    subject do
      commits = project.commits_between("a6d1d4aca0c85816ddfd27d93773f43a31395033",
                                        "2fb376f61875b58bceee0492e270e9c805294b1a")
      commits.map { |c| c.id }
    end

    it { should have(2).elements }
    it { should include("2fb376f61875b58bceee0492e270e9c805294b1a") }
    it { should include("4571e226fbcd7be1af16e9fa1e13b7ac003bebdf") }
    it { should_not include("a6d1d4aca0c85816ddfd27d93773f43a31395033") }
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
#  id                     :integer         not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  private_flag           :boolean         default(TRUE), not null
#  code                   :string(255)
#  owner_id               :integer
#  default_branch         :string(255)     default("master"), not null
#  issues_enabled         :boolean         default(TRUE), not null
#  wall_enabled           :boolean         default(TRUE), not null
#  merge_requests_enabled :boolean         default(TRUE), not null
#

