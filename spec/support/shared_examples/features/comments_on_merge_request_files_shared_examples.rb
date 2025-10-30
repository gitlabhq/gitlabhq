# frozen_string_literal: true

RSpec.shared_examples 'comment on merge request file' do
  it 'adds a comment' do
    if Users::ProjectStudio.enabled_for_user?(user)
      click_diff_line(find_in_panel_by_scrolling("[id='#{sample_commit.line_code}']"))
    else
      click_diff_line(find_by_scrolling("[id='#{sample_commit.line_code}']"))
    end

    page.within('.js-discussion-note-form') do
      fill_in(:note_note, with: 'Line is wrong')
      find('.js-comment-button').click
    end

    wait_for_requests

    page.within('.notes_holder') do
      expect(page).to have_content('Line is wrong')
      expect(page).not_to have_content('Comment on lines')
    end

    visit(merge_request_path(merge_request))

    page.within('.notes .discussion') do
      expect(page).to have_content("#{user.name} #{user.to_reference} started a thread")
      expect(page).to have_content(sample_commit.line_code_path)
      expect(page).to have_content('Line is wrong')
    end

    page.within('.notes-tab .badge') do
      expect(page).to have_content('1')
    end
  end
end
