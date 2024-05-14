# frozen_string_literal: true

RSpec.shared_examples 'user applies wiki templates' do
  before do
    create(:wiki_page, wiki: wiki, title: 'templates/Template title 1', content: 'Template 1 content')
    create(:wiki_page, wiki: wiki, title: 'templates/Template title 2', content: 'Template 2 content')

    click_link "New page"
  end

  it 'shows the templates in the dropdown' do
    click_on "Choose a template"

    expect(page).to have_css("li", text: "Template title 1")
    expect(page).to have_css("li", text: "Template title 2")
  end

  it 'applies the template on select' do
    click_on "Choose a template"
    page.find("li", text: "Template title 1").click

    expect(page).to have_field("wiki[content]", with: "Template 1 content")
  end

  it 'shows warning if existing text will be overridden by the template' do
    fill_in "wiki[content]", with: "Existing content"

    click_on "Choose a template"
    page.find("li", text: "Template title 1").click

    expect(page).to have_field("wiki[content]", with: "Existing content")

    expect(page).to have_content("Applying a template will replace the existing content.")
    expect(page).to have_content("Any changes you have made will be lost.")

    click_on "Apply template"

    expect(page).to have_field("wiki[content]", with: "Template 1 content")
  end
end
