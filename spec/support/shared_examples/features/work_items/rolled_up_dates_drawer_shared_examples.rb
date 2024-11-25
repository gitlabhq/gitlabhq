# frozen_string_literal: true

RSpec.shared_examples 'work items rolled up dates in drawer' do
  include WorkItemFeedbackHelpers

  let(:work_item_rolledup_dates_selector) { '[data-testid="work-item-rolledup-dates"]' }
  let(:work_item_start_due_dates_selector) { '[data-testid="work-item-start-due-dates"]' }
  let(:work_item_milestone_selector) { '[data-testid="work-item-milestone"]' }

  context 'when feature flag is enabled' do
    before do
      stub_licensed_features(epics: true, subepics: true, epic_colors: true)

      page.refresh
      wait_for_all_requests

      close_work_item_feedback_popover_if_present
    end

    it 'passes axe automated accessibility testing in closed state' do
      expect(page).to have_selector(work_item_rolledup_dates_selector)
      expect(page).to be_axe_clean.within(work_item_rolledup_dates_selector)
    end

    it 'passes axe automated accessibility testing in open state' do
      within(work_item_rolledup_dates_selector) do
        click_button _('Edit')
        wait_for_requests

        expect(page).to be_axe_clean.within(work_item_rolledup_dates_selector)
      end
    end

    context 'when edit is clicked' do
      it 'selects and updates the dates to fixed once selected', :aggregate_failures do
        expect(find_field('Inherited')).to be_checked

        find_and_click_edit(work_item_rolledup_dates_selector)

        within work_item_rolledup_dates_selector do
          fill_in 'Start', with: '2021-01-01'
          fill_in 'Due', with: '2021-01-02'
        end

        # Click outside to save
        find_by_testid("work-item-title").click

        within work_item_rolledup_dates_selector do
          expect(find_field('Fixed')).to be_checked
          expect(page).to have_text('Start: Jan 1, 2021')
          expect(page).to have_text('Due: Jan 2, 2021')
        end
      end
    end
  end
end
