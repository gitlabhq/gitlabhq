# frozen_string_literal: true

RSpec.shared_examples 'work item drawer' do
  include MobileHelpers

  before do
    first_card.click
    wait_for_requests
  end

  it 'shows drawer when clicking issue' do
    expect(page).to have_selector('[data-testid="work-item-drawer"]')
  end

  it 'focus on first element of the drawer when clicking issue' do
    expect(page).to have_selector('[data-testid="work-item-drawer-ref-link"]', focused: true)
  end

  it 'closes drawer when clicking issue' do
    expect(page).to have_selector('[data-testid="work-item-drawer"]')

    first_card.click

    expect(page).not_to have_selector('[data-testid="work-item-drawer"]')
  end

  it 'shows issue details when drawer is open', :aggregate_failures do
    within_testid('work-item-drawer') do
      expect(page).to have_content(issue.title)
    end
  end

  context 'when clicking close button' do
    before do
      find('[data-testid="work-item-drawer"] .gl-drawer-close-button').click
    end

    it 'unhighlights the active issue card' do
      expect(first_card[:class]).not_to include('is-active')
      expect(first_card[:class]).not_to include('multi-select')
    end

    it 'closes drawer when clicking close button' do
      expect(page).not_to have_selector('[data-testid="work-item-drawer"]')
    end
  end

  context 'when editing issue title' do
    it 'edits issue title' do
      within_testid('work-item-drawer') do
        find_by_testid('work-item-edit-form-button').click

        find_by_testid('work-item-title-input').set('Test title')

        click_button 'Save changes'

        wait_for_requests

        expect(page).to have_content('Test title')
      end

      expect(first_card).to have_content('Test title')
    end
  end

  context 'when in notifications subscription' do
    before do
      within_testid('work-item-drawer') do
        find_by_testid('work-item-actions-dropdown').click
      end
    end

    it 'displays notifications toggle', :aggregate_failures do
      within_testid('work-item-drawer') do
        expect(page).to have_selector('[data-testid="notifications-toggle-form"]')
        expect(page).to have_content('Notifications')
        expect(page).not_to have_content('Disabled by project owner')
      end
    end

    it 'shows toggle as on then as off as user toggles to subscribe and unsubscribe', :aggregate_failures do
      within_testid('notifications-toggle-form') do
        subscription_button = find('[data-testid="toggle-wrapper"] button')

        expect(page).not_to have_css("button.is-checked")

        subscription_button.click

        wait_for_requests

        expect(page).to have_css("button.is-checked")

        subscription_button.click

        wait_for_requests

        expect(page).not_to have_css("button.is-checked")
      end
    end
  end

  context 'when editing confidentiality' do
    before do
      within_testid('work-item-drawer') do
        find_by_testid('work-item-actions-dropdown').click
      end
    end

    it 'make issue confidential' do
      within_testid('work-item-drawer') do
        expect(page).not_to have_content('Confidential')

        find_by_testid('confidentiality-toggle-action').click

        wait_for_requests

        expect(page).to have_content('Confidential')
      end
    end
  end

  context 'in time tracking' do
    it 'displays time tracking feature with default message' do
      within_testid('work-item-time-tracking') do
        expect(page).to have_content('Time tracking')
        expect(page).to have_content('Add an estimate or time spent')
      end
    end

    context 'when only spent time is recorded' do
      before do
        issue.timelogs.create!(time_spent: 3600, user: user)

        page.refresh

        wait_for_requests
      end

      it 'shows the total time spent only' do
        within_testid('work-item-time-tracking') do
          expect(page).to have_content('Spent 1h')
          expect(page).not_to have_content('Estimated')
        end
      end
    end

    context 'when only estimated time is recorded' do
      before do
        issue.update!(time_estimate: 3600)

        page.refresh

        wait_for_requests
      end

      it 'shows the estimated time only', :aggregate_failures do
        within_testid('work-item-time-tracking') do
          expect(page).to have_content('Estimate 1h')
          expect(page).to have_content('Spent 0h')
        end
      end
    end

    context 'when estimated and spent times are available' do
      before do
        issue.timelogs.create!(time_spent: 1800, user: user)
        issue.update!(time_estimate: 3600)

        page.refresh

        wait_for_requests
      end

      it 'shows time tracking progress bar' do
        within_testid('work-item-time-tracking') do
          expect(page).to have_selector('.gl-progress')
        end
      end

      it 'shows both estimated and spent time text', :aggregate_failures do
        within_testid('work-item-time-tracking') do
          expect(page).to have_content('Spent 30m')
          expect(page).to have_content('Estimate 1h')
        end
      end
    end
  end
end
