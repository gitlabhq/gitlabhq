# frozen_string_literal: true

RSpec.shared_examples 'shows public projects' do
  it 'shows projects' do
    expect(page).to have_content(public_project.title)
    expect(page).not_to have_content(internal_project.title)
    expect(page).not_to have_content(private_project.title)
    expect(page).not_to have_content(archived_project.title)
  end
end

RSpec.shared_examples 'shows public and internal projects' do
  it 'shows projects' do
    expect(page).to have_content(public_project.title)
    expect(page).to have_content(internal_project.title)
    expect(page).not_to have_content(private_project.title)
    expect(page).not_to have_content(archived_project.title)
  end
end
