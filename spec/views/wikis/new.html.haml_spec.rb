require 'spec_helper'

describe "wikis/new" do
  before(:each) do
    assign(:wiki, stub_model(Wiki,
      :title => "MyString",
      :content => "MyText"
    ).as_new_record)
  end

  it "renders new wiki form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => wikis_path, :method => "post" do
      assert_select "input#wiki_title", :name => "wiki[title]"
      assert_select "textarea#wiki_content", :name => "wiki[content]"
    end
  end
end
