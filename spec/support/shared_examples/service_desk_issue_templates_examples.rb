# frozen_string_literal: true

RSpec.shared_examples 'issue description templates from current project only' do
  it 'loads issue description templates from the project only' do
    within('#service-desk-template-select') do
      expect(page).to have_content(:all, 'project-issue-bar')
      expect(page).to have_content(:all, 'project-issue-foo')
      expect(page).not_to have_content(:all, 'group-issue-bar')
      expect(page).not_to have_content(:all, 'group-issue-foo')
    end
  end
end
