shared_examples 'comment on merge request file' do
  it 'adds a comment' do
    click_diff_line(find("[id='#{sample_commit.line_code}']"))

    page.within('.js-discussion-note-form') do
      fill_in(:note_note, with: 'Line is wrong')
      click_button('Comment')
    end

    wait_for_requests

    page.within('.notes_holder') do
      expect(page).to have_content('Line is wrong')
    end

    visit(merge_request_path(merge_request))

    page.within('.notes .discussion') do
      expect(page).to have_content("#{user.name} #{user.to_reference} started a discussion")
      expect(page).to have_content(sample_commit.line_code_path)
      expect(page).to have_content('Line is wrong')
    end

    page.within('.notes-tab .badge') do
      expect(page).to have_content('1')
    end
  end
end
