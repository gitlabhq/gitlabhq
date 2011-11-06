require 'spec_helper'

describe "Issues" do
  before do
    login_as :user
  end

  describe "GET /keys" do
    before do
      @key = Factory :key, :user => @user
      visit keys_path
    end

    subject { page }

    it { should have_content(@key.title) }

    describe "Destroy" do
      it "should remove entry" do
        expect {
          click_link "destroy_key_#{@key.id}"
        }.to change { @user.keys.count }.by(-1)
      end
    end
  end

  describe "New key", :js => true do
    before do
      visit keys_path
      click_link "Add new"
    end

    it "should open new key popup" do
      page.should have_content("Add new public key")
    end

    describe "fill in" do
      before do
        fill_in "key_title", :with => "laptop"
        fill_in "key_key", :with => "publickey234="
      end

      it { expect { click_button "Save" }.to change {Key.count}.by(1) }

      it "should add new key to table" do
        click_button "Save"

        page.should_not have_content("Add new public key")
        page.should have_content "laptop"
        page.should have_content "publickey234="
      end
    end
  end
end
