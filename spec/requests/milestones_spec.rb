require 'spec_helper'

describe "Milestones" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :admin)

    @milestone = Factory :milestone, :project => project
    @issue = Factory :issue, :project => project
    
    @milestone.issues << @issue
  end

  describe "GET /milestones" do
    before do 
      visit project_milestones_path(project)
    end

    subject { page }

    it { should have_content(@milestone.title[0..10]) }
    it { should have_content(@milestone.expires_at) }
    it { should have_content("Browse Issues") }
  end

  describe "GET /milestone/:id" do 
    before do 
      visit project_milestone_path(project, @milestone)
    end

    subject { page }

    it { should have_content(@milestone.title[0..10]) }
    it { should have_content(@milestone.expires_at) }
    it { should have_content("Browse Issues") }
  end

  describe "GET /milestones/new" do 
    before do
      visit new_project_milestone_path(project)
      fill_in "milestone_title", :with => "v2.3" 
      click_button "Create milestone"
    end

    it { current_path.should == project_milestone_path(project, project.milestones.last) }
    it { page.should have_content(project.milestones.last.title[0..10]) }
    it { page.should have_content(project.milestones.last.expires_at) }
  end
end
