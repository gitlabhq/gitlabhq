# frozen_string_literal: true

RSpec.shared_examples 'issuable time tracker' do |issuable_type|
  before do
    project.add_maintainer(maintainer)
    gitlab_sign_in(maintainer)
    visit public_send("project_#{issuable_type}_path", project, issuable)
    wait_for_all_requests
  end

  after do
    wait_for_requests
  end

  it 'renders the sidebar component empty state' do
    page.within '[data-testid="noTrackingPane"]' do
      expect(page).to have_content 'No estimate or time spent'
    end
  end

  it 'updates the sidebar component when estimate is added' do
    submit_time('/estimate 3w 1d 1h')

    wait_for_requests
    page.within '[data-testid="estimateOnlyPane"]' do
      expect(page).to have_content '3w 1d 1h'
    end
  end

  it 'updates the sidebar component when spent is added' do
    submit_time('/spend 3w 1d 1h')

    wait_for_requests
    page.within '[data-testid="spentOnlyPane"]' do
      expect(page).to have_content '3w 1d 1h'
    end
  end

  it 'shows the comparison when estimate and spent are added' do
    submit_time('/estimate 3w 1d 1h')
    submit_time('/spend 3w 1d 1h')

    wait_for_requests
    page.within '[data-testid="timeTrackingComparisonPane"]' do
      expect(page).to have_content '3w 1d 1h'
    end
  end

  it 'updates the sidebar component when estimate is removed' do
    submit_time('/estimate 3w 1d 1h')
    submit_time('/remove_estimate')

    page.within '.time-tracking-component-wrap' do
      expect(page).to have_content 'No estimate or time spent'
    end
  end

  it 'updates the sidebar component when spent is removed' do
    submit_time('/spend 3w 1d 1h')
    submit_time('/remove_time_spent')

    page.within '.time-tracking-component-wrap' do
      expect(page).to have_content 'No estimate or time spent'
    end
  end

  it 'shows the help state when icon is clicked' do
    page.within '.time-tracking-component-wrap' do
      find('.help-button').click
      expect(page).to have_content 'Track time with quick actions'
      expect(page).to have_content 'Learn more'
    end
  end

  it 'shows the time tracking report when link is clicked' do
    submit_time('/estimate 1w')
    submit_time('/spend 1d')

    wait_for_requests

    page.within '.time-tracking-component-wrap' do
      click_link 'Time tracking report'

      wait_for_requests
    end

    page.within '#time-tracking-report' do
      expect(find('tbody')).to have_content maintainer.name
      expect(find('tbody')).to have_content '1d'
    end
  end

  it 'hides the help state when close icon is clicked' do
    page.within '.time-tracking-component-wrap' do
      find('.help-button').click
      find('.close-help-button').click

      expect(page).not_to have_content 'Track time with quick actions'
      expect(page).not_to have_content 'Learn more'
    end
  end

  it 'displays the correct help url' do
    page.within '.time-tracking-component-wrap' do
      find('.help-button').click

      expect(find_link('Learn more')[:href]).to have_content('/help/user/project/time_tracking.md')
    end
  end
end

def submit_time(quick_action)
  fill_in 'note[note]', with: quick_action
  find('[data-testid="comment-button"]').click
  wait_for_requests
end
