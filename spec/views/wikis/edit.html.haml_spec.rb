require 'spec_helper'

describe "wikis/edit" do
  before(:each) do
    @wiki = assign(:wiki, stub_model(Wiki,
      :title => "MyString",
      :content => "MyText"
    ))
  end

  it "renders the edit wiki form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => wikis_path(@wiki), :method => "post" do
      assert_select "input#wiki_title", :name => "wiki[title]"
      assert_select "textarea#wiki_content", :name => "wiki[content]"
    end
  end
end
