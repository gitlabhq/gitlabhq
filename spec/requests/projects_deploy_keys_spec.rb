require 'spec_helper'

describe "Projects", "DeployKeys" do
  let(:project) { Factory :project }

  before do
    login_as :user
    project.add_access(@user, :read, :write, :admin)
  end

  describe "GET /keys" do
    before do
      @key = Factory :key, :project => project
      visit project_deploy_keys_path(project)
    end

    subject { page }

    it { should have_content(@key.title) }

    describe "Destroy" do
      before { visit project_deploy_key_path(project, @key) }

      it "should remove entry" do
        expect {
          click_link "Remove"
        }.to change { project.deploy_keys.count }.by(-1)
      end
    end
  end

  describe "New key" do
    before do
      visit project_deploy_keys_path(project)
      click_link "New Deploy Key"
    end

    it "should open new key popup" do
      page.should have_content("New Deploy key")
    end

    describe "fill in" do
      before do
        fill_in "key_title", :with => "laptop"
        fill_in "key_key", :with => "publickey234="
      end

      it { expect { click_button "Save" }.to change {Key.count}.by(1) }

      it "should add new key to table" do
        click_button "Save"

        page.should have_content "laptop"
      end
    end
  end

  describe "Show page" do 
    before do
      @key = Factory :key, :project => project
      visit project_deploy_key_path(project, @key) 
    end
    
    it { page.should have_content @key.title }
    it { page.should have_content @key.key[0..10] }
  end
end
