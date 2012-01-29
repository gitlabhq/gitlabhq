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
      before { visit key_path(@key) }

      it "should remove entry" do
        expect {
          click_link "Remove"
        }.to change { @user.keys.count }.by(-1)
      end
    end
  end

  describe "New key" do
    before do
      visit keys_path
      click_link "Add new"
    end

    it "should open new key popup" do
      page.should have_content("New key")
    end

    describe "fill in" do
      before do
        fill_in "key_title", :with => "laptop"
        fill_in "key_key", :with => "publickey234="
      end

      it { expect { click_button "Save" }.to change {Key.count}.by(1) }

      it "should add new key to table" do
        click_button "Save"

        page.should_not have_content("New key")
        page.should have_content "laptop"
      end
    end
  end

  describe "Show page" do 
    before do
      @key = Factory :key, :user => @user
      visit key_path(@key) 
    end
    
    it { page.should have_content @key.title }
    it { page.should have_content @key.key[0..10] }
  end
end
