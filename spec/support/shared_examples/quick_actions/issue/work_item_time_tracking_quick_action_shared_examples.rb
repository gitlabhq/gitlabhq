# frozen_string_literal: true

RSpec.shared_examples 'work item time tracker' do
  include Spec::Support::Helpers::ModalHelpers

  before do
    project.add_maintainer(maintainer)
    gitlab_sign_in(maintainer)
    visit project_issue_path(project, issuable)
  end

  it 'renders the sidebar component empty state' do
    within_testid('work-item-time-tracking') do
      expect(page).to have_text 'Add an estimate or time spent'
      expect(page).to have_button 'estimate'
      expect(page).to have_button 'time spent'
    end
  end

  it 'updates the sidebar component when estimate is added, edited, and removed' do
    add_comment('/estimate 3w 1d 1h')

    within_testid('work-item-time-tracking') do
      expect(page).to have_text 'Spent 0h'
      expect(page).to have_button '0h'
      expect(page).to have_text 'Estimate 16d 1h'
      expect(page).to have_button '16d 1h'
    end

    click_button '16d 1h'

    within_modal do
      expect(page).to have_css('h2', text: 'Edit time estimate')

      fill_in 'Estimate', with: '3w 3d'
      click_button 'Save'
    end

    within_testid('work-item-time-tracking') do
      expect(page).to have_text 'Spent 0h'
      expect(page).to have_button '0h'
      expect(page).to have_text 'Estimate 18d'
      expect(page).to have_button '18d'
    end

    add_comment('/remove_estimate')

    within_testid('work-item-time-tracking') do
      expect(page).not_to have_text 'Estimate 18d'
      expect(page).not_to have_button '18d'
      expect(page).to have_text 'Add an estimate or time spent'
    end
  end

  it 'updates the sidebar component when spent is added and removed' do
    add_comment('/spend 3w 1d 1h')

    within_testid('work-item-time-tracking') do
      expect(page).to have_text 'Spent 16d 1h'
      expect(page).to have_button '16d 1h'
      expect(page).to have_button 'Add estimate'
    end

    add_comment('/remove_time_spent')

    within_testid('work-item-time-tracking') do
      expect(page).not_to have_text 'Spent 16d 1h'
      expect(page).not_to have_button '16d 1h'
      expect(page).to have_text 'Add an estimate or time spent'
    end
  end

  it 'shows the comparison when estimate and spent are added' do
    add_comment('/estimate 3w 1d 2h')
    add_comment('/spend 3w 1d 1h')

    within_testid('work-item-time-tracking') do
      expect(page).to have_text 'Spent 16d 1h'
      expect(page).to have_button '16d 1h'
      expect(page).to have_text 'Estimate 16d 2h'
      expect(page).to have_button '16d 2h'
    end
  end

  it 'shows time tracking report and removes time log when deleted' do
    add_comment('/estimate 1w')
    add_comment("/spend 1d #{5.days.ago.strftime('%F')}")
    click_button 'Add time entry'

    within_modal do
      expect(page).to have_css('h2', text: 'Add time entry')

      fill_in 'Time spent', with: '3d'
      click_button 'Save'
    end

    click_button '4d'

    within_modal do
      expect(page).to have_css('h2', text: 'Time tracking report')
      expect(page).to have_css('tbody tr:nth-child(1)', text: '3d')
      expect(page).to have_css('tbody tr:nth-child(2)', text: '1d')
      expect(page).to have_css('tfoot', text: '4d') # total time spent

      page.within 'tbody tr:nth-child(2)' do
        click_button 'Delete time spent'
      end

      expect(page).to have_css('tbody tr:nth-child(1)', text: '3d')
      expect(page).not_to have_css('tbody tr:nth-child(2)')
      expect(page).to have_css('tfoot', text: '3d') # total time spent

      click_button 'Close'
    end

    within_testid('work-item-time-tracking') do
      expect(page).to have_text 'Spent 3d'
    end
  end
end

def add_comment(quick_action)
  fill_in 'Add a reply', with: quick_action
  click_button 'Comment'
end
