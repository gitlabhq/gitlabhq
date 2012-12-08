require 'spec_helper'

describe "Projects" do
  before { login_as :user }

  describe "GET /projects/show" do
    before do
      @project = create(:project, owner: @user)
      @project.add_access(@user, :read)

      visit project_path(@project)
    end

    it "should be correct path" do
      current_path.should == project_path(@project)
    end
  end

  describe "GET /projects/:id/edit" do
    before do
      @project = create(:project)
      @project.add_access(@user, :admin, :read)

      visit edit_project_path(@project)
    end

    it "should be correct path" do
      current_path.should == edit_project_path(@project)
    end

    it "should have labels for new project" do
      page.should have_content("Project name is")
      page.should have_content("Advanced settings:")
      page.should have_content("Features:")
    end
  end

  describe "PUT /projects/:id" do
    before do
      @project = create(:project, owner: @user)
      @project.add_access(@user, :admin, :read)

      visit edit_project_path(@project)

      fill_in 'project_name', with: 'Awesome'
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

  describe "DELETE /projects/:id" do
    before do
      @project = create(:project, owner: @user)
      @project.add_access(@user, :read, :admin)
      visit edit_project_path(@project)
    end

    it "should be correct path" do
      expect { click_link "Remove" }.to change {Project.count}.by(-1)
    end
  end
end
