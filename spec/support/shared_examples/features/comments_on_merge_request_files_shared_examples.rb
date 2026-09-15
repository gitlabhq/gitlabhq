# frozen_string_literal: true

RSpec.shared_examples 'comment on merge request file' do
  it 'adds a comment' do
    line_holder = find_line(sample_commit.line_code, sample_commit.line_code_path)
    click_diff_line(line_holder)

    discussion_row = next_discussion_row(line_holder)
    discussion_row.fill_in('note[note]', with: 'Line is wrong')
    click_button('Add comment now')

    wait_for_requests

    expect(discussion_row).to have_content('Line is wrong')
    expect(discussion_row).not_to have_content('Comment on lines')

    visit(merge_request_path(merge_request))

    page.within('.notes .discussion') do
      expect(page).to have_content("#{user.name} #{user.to_reference} started a thread")
      expect(page).to have_content(sample_commit.line_code_path)
      expect(page).to have_content('Line is wrong')
    end

    within_testid('notes-tab') do
      expect(page).to have_content('1')
    end
  end
end
