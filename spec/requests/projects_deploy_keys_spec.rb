require 'spec_helper'

describe "Projects", "DeployKeys" do
  let(:project) { create(:project) }

  before do
    login_as :user
    project.team << [@user, :master]
  end

  describe "GET /keys" do
    before do
      @key = create(:key, project: project)
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
        fill_in "key_title", with: "laptop"
        fill_in "key_key", with: "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzrEJUIR6Y03TCE9rIJ+GqTBvgb8t1jI9h5UBzCLuK4VawOmkLornPqLDrGbm6tcwM/wBrrLvVOqi2HwmkKEIecVO0a64A4rIYScVsXIniHRS6w5twyn1MD3sIbN+socBDcaldECQa2u1dI3tnNVcs8wi77fiRe7RSxePsJceGoheRQgC8AZ510UdIlO+9rjIHUdVN7LLyz512auAfYsgx1OfablkQ/XJcdEwDNgi9imI6nAXhmoKUm1IPLT2yKajTIC64AjLOnE0YyCh6+7RFMpiMyu1qiOCpdjYwTgBRiciNRZCH8xIedyCoAmiUgkUT40XYHwLuwiPJICpkAzp7Q== user@laptop"
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
      @key = create(:key, project: project)
      visit project_deploy_key_path(project, @key)
    end

    it { page.should have_content @key.title }
    it { page.should have_content @key.key[0..10] }
  end
end
