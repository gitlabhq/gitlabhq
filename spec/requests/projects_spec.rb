require 'spec_helper'

describe "Projects" do
  before { login_as :user }

  describe "GET /projects" do
    before do
      @project = Factory :project, :owner => @user
      @project.add_access(@user, :read)
      visit projects_path
    end

    it "should be on projects page" do
      current_path.should == projects_path
    end

    it "should have link to new project" do
      page.should have_content("New Project")
    end

    it "should have project" do 
      page.should have_content(@project.name)
    end
  end

  describe "GET /projects/new" do
    before do
      visit projects_path
      click_link "New Project"
    end

    it "should be correct path" do
      current_path.should == new_project_path
    end

    it "should have labels for new project" do
      page.should have_content("Name")
      page.should have_content("Path")
      page.should have_content("Description")
    end
  end

  describe "POST /projects" do
    before do
      visit new_project_path
      fill_in 'Name', :with => 'NewProject'
      fill_in 'Code', :with => 'NPR'
      fill_in 'Path', :with => 'newproject'
      expect { click_button "Save" }.to change { Project.count }.by(1)
      @project = Project.last
    end

    it "should be correct path" do
      current_path.should == project_path(@project)
    end

    it "should show project" do
      page.should have_content(@project.name)
      page.should have_content(@project.path)
      page.should have_content(@project.description)
    end

    it "should init repo instructions" do
      page.should have_content("git remote")
      page.should have_content(@project.url_to_repo)
    end
  end

  describe "GET /projects/show" do
    before do
      @project = Factory :project, :owner => @user
      @project.add_access(@user, :read)

      visit project_path(@project)
    end

    it "should be correct path" do
      current_path.should == project_path(@project)
    end

    # TODO: replace with real one
    #it "should beahave like activities page" do
      #within ".project-update"  do
        #page.should have_content("master")
        #page.should have_content(@project.commit.author.name)
        #page.should have_content(@project.commit.safe_message)
      #end
    #end
  end

  describe "GET /projects/team" do
    before do
      @project = Factory :project
      @project.add_access(@user, :read)

      visit team_project_path(@project,
                              :path => ValidCommit::BLOB_FILE_PATH,
                              :commit_id => ValidCommit::ID)
    end

    it "should be correct path" do
      current_path.should == team_project_path(@project)
    end

    it "should have as as team member" do
      page.should have_content(@user.name)
    end
  end

  describe "GET /projects/:id/edit" do
    before do
      @project = Factory :project
      @project.add_access(@user, :admin, :read)

      visit edit_project_path(@project)
    end

    it "should be correct path" do
      current_path.should == edit_project_path(@project)
    end

    it "should have labels for new project" do
      page.should have_content("Name")
      page.should have_content("Path")
      page.should have_content("Description")
    end
  end

  describe "PUT /projects/:id" do
    before do
      @project = Factory :project, :owner => @user
      @project.add_access(@user, :admin, :read)

      visit edit_project_path(@project)

      fill_in 'Name', :with => 'Awesome'
      fill_in 'Path', :with => 'legit'
      fill_in 'Description', :with => 'Awesome project'
      click_button "Save"
      @project = @project.reload
    end

    it "should be correct path" do
      current_path.should == edit_project_path(@project)
    end

    it "should show project" do
      page.should have_content("Awesome")
    end
  end

  #describe "DELETE /projects/:id", :js => true do
    #before do
      #@project = Factory :project
      #@project.add_access(@user, :read, :admin)
      #visit projects_path
    #end

    #it "should be correct path" do
      #expect { click_link "Destroy" }.to change {Project.count}.by(1)
    #end
  #end
end
