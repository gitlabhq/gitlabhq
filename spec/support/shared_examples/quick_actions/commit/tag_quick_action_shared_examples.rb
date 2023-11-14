# frozen_string_literal: true

RSpec.shared_examples 'tag quick action' do
  context "post note to existing commit" do
    it 'tags this commit' do
      add_note("/tag #{tag_name} #{tag_message}")

      expect(page).to have_content %(Tagged this commit to #{tag_name} with "#{tag_message}".)
      expect(page).to have_content "tagged commit #{truncated_commit_sha}"
      expect(page).to have_content tag_name

      visit project_tag_path(project, tag_name)
      expect(page).to have_content tag_name
      expect(page).to have_content tag_message
      expect(page).to have_content truncated_commit_sha
    end
  end

  context 'preview', :js do
    it 'removes quick action from note and explains it' do
      preview_note("/tag #{tag_name} #{tag_message}")

      expect(page).not_to have_content '/tag'
      expect(page).to have_content %(Tags this commit to #{tag_name} with "#{tag_message}")
      expect(page).to have_content tag_name
    end
  end
end
