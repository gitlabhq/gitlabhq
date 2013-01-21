# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  action      :integer
#  author_id   :integer
#

require 'spec_helper'

describe Event do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:target) }
  end

  describe "Respond to" do
    it { should respond_to(:author_name) }
    it { should respond_to(:author_email) }
    it { should respond_to(:issue_title) }
    it { should respond_to(:merge_request_title) }
    it { should respond_to(:commits) }
  end

  describe "Push event" do
    before do
      project = create(:project)
      @user = project.owner

      data = {
        before: "0000000000000000000000000000000000000000",
        after: "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
        ref: "refs/heads/master",
        user_id: @user.id,
        user_name: @user.name,
        repository: {
          name: project.name,
          url: "localhost/rubinius",
          description: "",
          homepage: "localhost/rubinius",
          private: true
        }
      }

      @event = Event.create(
        project: project,
        action: Event::Pushed,
        data: data,
        author_id: @user.id
      )
    end

    it { @event.push?.should be_true }
    it { @event.proper?.should be_true }
    it { @event.new_branch?.should be_true }
    it { @event.tag?.should be_false }
    it { @event.branch_name.should == "master" }
    it { @event.author.should == @user }
  end

  describe 'Team events' do
    let(:user_project) { stub.as_null_object }
    let(:observer) { UsersProjectObserver.instance }

    before {
      Event.should_receive :create
    }

    describe "Joined project team" do
      it "should create event" do
        observer.after_create user_project
      end
    end

    describe "Left project team" do
      it "should create event" do
        observer.after_destroy user_project
      end
    end
  end
end
