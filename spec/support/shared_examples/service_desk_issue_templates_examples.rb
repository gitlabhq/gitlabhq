# frozen_string_literal: true

RSpec.shared_examples 'issue description templates from current project only' do
  it 'loads issue description templates from the project only' do
    within('#service-desk-template-select') do
      expect(page).to have_content('project-issue-bar')
      expect(page).to have_content('project-issue-foo')
      expect(page).not_to have_content('group-issue-bar')
      expect(page).not_to have_content('group-issue-foo')
    end
  end
end
