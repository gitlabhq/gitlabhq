require 'spec_helper'

describe "Last Push widget" do
  before { login_as :user }

  before do
    @project = Factory :project, :owner => @user
    @project.add_access(@user, :read)
    create_push_event
    visit dashboard_path
  end

  it "should display last push widget with link to merge request page" do
    page.should have_content "Your last push was to branch new_design"
    page.should have_link "Create Merge Request"
  end

  describe "click create MR" do
    before { click_link "Create Merge Request" }

    it { current_path.should == new_project_merge_request_path(@project) }
    it { find("#merge_request_source_branch").value.should == "new_design" }
    it { find("#merge_request_target_branch").value.should == "master" }
    it { find("#merge_request_title").value.should == "New Design" }
  end


  def create_push_event
    data = {
      :before => "0000000000000000000000000000000000000000",
      :after => "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
      :ref => "refs/heads/new_design",
      :user_id => @user.id,
      :user_name => @user.name,
      :repository => {
        :name => @project.name,
        :url => "localhost/rubinius",
        :description => "",
        :homepage => "localhost/rubinius",
        :private => true
      }
    }

    @event = Event.create(
      :project => @project,
      :action => Event::Pushed,
      :data => data,
      :author_id => @user.id
    )
  end
end

