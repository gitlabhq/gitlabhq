# frozen_string_literal: true

RSpec.shared_examples 'issue boards sidebar' do
  include MobileHelpers

  before do
    first_card.click
    wait_for_requests
  end

  it 'shows sidebar when clicking issue' do
    expect(page).to have_selector('[data-testid="issue-boards-sidebar"]')
  end

  it 'closes sidebar when clicking issue' do
    expect(page).to have_selector('[data-testid="issue-boards-sidebar"]')

    first_card.click

    expect(page).not_to have_selector('[data-testid="issue-boards-sidebar"]')
  end

  it 'shows issue details when sidebar is open', :aggregate_failures do
    page.within('[data-testid="issue-boards-sidebar"]') do
      expect(page).to have_content(issue.title)
      expect(page).to have_content(issue.to_reference)
    end
  end

  context 'when clicking close button' do
    before do
      find('[data-testid="issue-boards-sidebar"] .gl-drawer-close-button').click
    end

    it 'unhighlights the active issue card' do
      expect(first_card[:class]).not_to include('is-active')
      expect(first_card[:class]).not_to include('multi-select')
    end

    it 'closes sidebar when clicking close button' do
      expect(page).not_to have_selector('[data-testid="issue-boards-sidebar"]')
    end
  end

  context 'editing issue title' do
    it 'edits issue title' do
      page.within('[data-testid="sidebar-title"]') do
        click_button 'Edit'

        wait_for_requests

        find('input').set('Test title')

        click_button 'Save changes'

        wait_for_requests

        expect(page).to have_content('Test title')
      end

      expect(first_card).to have_content('Test title')
    end
  end

  context 'editing issue milestone', :js do
    it_behaves_like 'milestone sidebar widget'
  end

  context 'editing issue due date', :js do
    it_behaves_like 'date sidebar widget'
  end

  context 'editing issue labels', :js do
    it_behaves_like 'labels sidebar widget'
  end

  context 'in notifications subscription' do
    it 'displays notifications toggle', :aggregate_failures do
      page.within('[data-testid="sidebar-notifications"]') do
        expect(page).to have_selector('[data-testid="subscription-toggle"]')
        expect(page).to have_content('Notifications')
        expect(page).not_to have_content('Disabled by project owner')
      end
    end

    it 'shows toggle as on then as off as user toggles to subscribe and unsubscribe', :aggregate_failures do
      wait_for_requests
      subscription_button = find('[data-testid="subscription-toggle"]')

      subscription_button.click

      expect(subscription_button).to have_css("button.is-checked")

      subscription_button.click

      wait_for_requests

      expect(subscription_button).to have_css("button:not(.is-checked)")
    end
  end

  context 'confidentiality' do
    it 'make issue confidential' do
      page.within('.confidentiality') do
        expect(page).to have_content('Not confidential')

        click_button 'Edit'
        expect(page).to have_css('.sidebar-item-warning-message')

        within('.sidebar-item-warning-message') do
          click_button 'Turn on'
        end

        wait_for_requests

        expect(page).to have_content(
          _('Only project members with at least the Planner role, the author, and assignees ' \
            'can view or be notified about this issue.')
        )
      end
    end
  end

  context 'in time tracking' do
    it 'displays time tracking feature with default message' do
      page.within('[data-testid="time-tracker"]') do
        expect(page).to have_content('Time tracking')
        expect(page).to have_content('No estimate or time spent')
      end
    end

    context 'when only spent time is recorded' do
      before do
        issue.timelogs.create!(time_spent: 3600, user: user)

        refresh_and_click_first_card
      end

      it 'shows the total time spent only' do
        page.within('[data-testid="time-tracker"]') do
          expect(page).to have_content('Spent: 1h')
          expect(page).not_to have_content('Estimated')
        end
      end
    end

    context 'when only estimated time is recorded' do
      before do
        issue.update!(time_estimate: 3600)

        refresh_and_click_first_card
      end

      it 'shows the estimated time only', :aggregate_failures do
        page.within('[data-testid="time-tracker"]') do
          expect(page).to have_content('Estimated: 1h')
          expect(page).not_to have_content('Spent')
        end
      end
    end

    context 'when estimated and spent times are available' do
      before do
        issue.timelogs.create!(time_spent: 1800, user: user)
        issue.update!(time_estimate: 3600)

        refresh_and_click_first_card
      end

      it 'shows time tracking progress bar' do
        page.within('[data-testid="time-tracker"]') do
          expect(page).to have_selector('[data-testid="timeTrackingComparisonPane"]')
        end
      end

      it 'shows both estimated and spent time text', :aggregate_failures do
        page.within('[data-testid="time-tracker"]') do
          expect(page).to have_content('Spent 30m')
          expect(page).to have_content('Est 1h')
        end
      end
    end

    context 'when limitedToHours instance option is turned on' do
      before do
        # 3600+3600*24 = 1d 1h or 25h
        issue.timelogs.create!(time_spent: 3600 + (3600 * 24), user: user)
        stub_application_setting(time_tracking_limit_to_hours: true)

        refresh_and_click_first_card
      end

      it 'shows the total time spent only' do
        page.within('[data-testid="time-tracker"]') do
          expect(page).to have_content('Spent: 25h')
        end
      end
    end
  end
end
