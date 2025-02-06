# frozen_string_literal: true

RSpec.shared_examples 'showing all projects' do
  it "renders the correct path" do
    expect(page).to have_current_path(admin_projects_path, ignore_query: true)
  end

  it 'renders projects list without archived project' do
    expect(page).to have_content(project.name)
    expect(page).not_to have_content(archived_project.name)
  end

  it 'renders all projects', :js do
    find(:css, '#sort-projects-dropdown').click
    click_link 'Show archived projects'

    expect(page).to have_content(project.name)
    expect(page).to have_content(archived_project.name)
    expect(page).to have_xpath("//span[@class='gl-badge badge badge-pill badge-info gl-mr-3']", text: 'Archived')
  end

  it 'renders only archived projects', :js do
    find(:css, '#sort-projects-dropdown').click
    click_link 'Show archived projects only'

    expect(page).to have_content(archived_project.name)
    expect(page).not_to have_content(project.name)
  end
end

RSpec.shared_examples 'showing project details' do
  it "has project info", :aggregate_failures do
    expect(page).to have_current_path admin_project_path(project), ignore_query: true
    expect(page).to have_content(project.path)
    expect(page).to have_content(project.name)
    expect(page).to have_content(project.full_name)
    expect(page).to have_content(project.creator.name)
    expect(page).to have_content(project.id)
  end
end
