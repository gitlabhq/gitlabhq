require 'spec_helper'

describe "Tags" do
  before { login_as :user }

  # describe "GET 'tags/index'" do
  #   it "should be successful" do
  #     get 'tags/index'
  #     response.should be_success
  #   end
  # end


  describe "GET '/tags/autocomplete'" do
    before do
     @project = Factory :project
     @project.add_access(@user, :read)
     @project.tag_list = 'demo1'
     @project.save
     visit '/tags/autocomplete.json'
    end


    it "should contains tags" do
      page.should have_content('demo1')
    end
end



end
