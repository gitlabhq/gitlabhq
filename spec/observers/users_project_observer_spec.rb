require 'spec_helper'

describe UsersProjectObserver do
  before(:each) { enable_observers }
  after(:each) { disable_observers }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  subject { UsersProjectObserver.instance }
  before { subject.stub(notification: double('NotificationService').as_null_object) }

  describe "#after_update" do
    before do
      @users_project = create :users_project
    end

    it "should called when UsersProject updated" do
      subject.should_receive(:after_update)
      @users_project.update_attribute(:project_access, UsersProject::MASTER)
    end

    it "should send email to user" do
      subject.should_receive(:notification)
      @users_project.update_attribute(:project_access, UsersProject::MASTER)
    end

    it "should not called after UsersProject destroyed" do
      subject.should_not_receive(:after_update)
      @users_project.destroy
    end
  end

  describe "#after_destroy" do
    before do
      @users_project = create :users_project
    end

    it "should called when UsersProject destroyed" do
      subject.should_receive(:after_destroy)
      @users_project.destroy
    end

    it "should create new event" do
      Event.should_receive(:create)
      @users_project.destroy
    end
  end

  describe "#after_create" do
    context 'wiki_enabled creates repository directory' do
      context 'wiki_enabled true creates wiki repository directory' do
        before do
          @project = create(:project, wiki_enabled: true)
          @path = GollumWiki.new(@project, user).send(:path_to_repo)
        end

        after do
          FileUtils.rm_rf(@path)
        end

        it { File.exists?(@path).should be_true }
      end

      context 'wiki_enabled false does not create wiki repository directory' do
        before do
          @project = create(:project, wiki_enabled: false)
          @path = GollumWiki.new(@project, user).send(:path_to_repo)
        end

        it { File.exists?(@path).should be_false }
      end
    end

    it "should send email to user" do
      subject.should_receive(:notification)
      Event.stub(create: true)

      create(:users_project)
    end

    it "should create new event" do
      Event.should_receive(:create)

      create(:users_project)
    end
  end
end
