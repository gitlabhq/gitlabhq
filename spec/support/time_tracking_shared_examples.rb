shared_examples 'issuable time tracker' do
  it 'renders the sidebar component empty state' do
    page.within '.issuable-sidebar' do
      expect(page).to have_content 'No estimate or time spent'
    end
  end

  it 'updates the sidebar component when estimate is added' do
    submit_time('/estimate 3w 1d 1h')

    page.within '.time-tracking-estimate-only' do
      expect(page).to have_content '3w 1d 1h'
    end
  end

  it 'updates the sidebar component when spent is added' do
    submit_time('/spend 3w 1d 1h')

    page.within '.time-tracking-spend-only' do
      expect(page).to have_content '3w 1d 1h'
    end
  end

  it 'shows the comparison when estimate and spent are added' do
    submit_time('/estimate 3w 1d 1h')
    submit_time('/spend 3w 1d 1h')

    page.within '.time-tracking-pane-compare' do
      expect(page).to have_content '3w 1d 1h'
    end
  end

  it 'updates the sidebar component when estimate is removed' do
    submit_time('/estimate 3w 1d 1h')
    submit_time('/remove_estimate')

    page.within '#issuable-time-tracker' do
      expect(page).to have_content 'No estimate or time spent'
    end
  end

  it 'updates the sidebar component when spent is removed' do
    submit_time('/spend 3w 1d 1h')
    submit_time('/remove_time_spent')

    page.within '#issuable-time-tracker' do
      expect(page).to have_content 'No estimate or time spent'
    end
  end

  it 'shows the help state when icon is clicked' do
    page.within '#issuable-time-tracker' do
      find('.help-button').click
      expect(page).to have_content 'Track time with slash commands'
      expect(page).to have_content 'Learn more'
    end
  end

  it 'hides the help state when close icon is clicked' do
    page.within '#issuable-time-tracker' do
      find('.help-button').click
      find('.close-help-button').click

      expect(page).not_to have_content 'Track time with slash commands'
      expect(page).not_to have_content 'Learn more'
    end
  end
end

def submit_time(slash_command)
  fill_in 'note[note]', with: slash_command
  click_button 'Comment'
  wait_for_ajax
end
