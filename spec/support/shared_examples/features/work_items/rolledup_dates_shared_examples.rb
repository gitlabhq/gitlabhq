# frozen_string_literal: true

RSpec.shared_examples 'work items rolled up dates' do
  let(:work_item_rolledup_dates_selector) { '[data-testid="work-item-rolledup-dates"]' }
  let(:work_item_start_due_dates_selector) { '[data-testid="work-item-start-due-dates"]' }
  let(:work_item_milestone_selector) { '[data-testid="work-item-milestone"]' }

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(work_items_rolledup_dates: false)

      page.refresh
      wait_for_all_requests
    end

    it 'does not show rolled up dates' do
      expect(page).not_to have_selector(work_item_rolledup_dates_selector)
    end
  end

  context 'when feature flag is enabled' do
    before do
      stub_feature_flags(work_items_rolledup_dates: true)

      page.refresh
      wait_for_all_requests

      # The feedback popover was hidding the child details popover close button
      within_testid('work-item-feedback-popover') do
        find_by_testid('close-button').click
      end
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

    context 'when using inheritable dates', :sidekiq_inline do
      def update_child_milestone(title:, milestone:)
        within_testid('links-child', text: title) do
          click_link(title)
          wait_for_all_requests
        end

        find_and_click_edit work_item_milestone_selector

        within_testid('work-item-milestone') do
          fill_in 'Milestone', with: milestone
        end

        page.refresh
        wait_for_all_requests
      end

      def update_child_date(title:, start_date:, due_date:)
        within_testid('links-child', text: title) do
          click_link(title)
          wait_for_all_requests
        end

        find_and_click_edit work_item_start_due_dates_selector
        # set empty value before the value to ensure
        # the current value don't mess with the new value input
        within_testid('work-item-start-due-dates') do
          fill_in 'Start', with: ""
          fill_in 'Start', with: start_date
          fill_in 'Due', with: "" # ensure to reset the input first to avoid wrong date values
          fill_in 'Due', with: due_date
        end

        find_by_testid('work-item-close').click
        wait_for_all_requests

        page.refresh
        wait_for_all_requests
      end

      def add_new_child(title:, milestone: nil, start_date: nil, due_date: nil)
        within_testid('work-item-tree') do
          click_button 'Add'
          click_button 'New issue'
          wait_for_all_requests

          fill_in 'Add a title', with: title
          click_button 'Create issue'
          wait_for_all_requests
        end

        if start_date.present? || due_date.present?
          update_child_date(title: title, start_date: start_date, due_date: due_date)
        end

        update_child_milestone(title: title, milestone: milestone) if milestone.present?
      end

      def add_existing_child(child_work_item)
        within_testid('work-item-tree') do
          click_button 'Add'
          click_button 'Existing issue'

          find_by_testid('work-item-token-select-input').set(child_work_item.title)
          wait_for_all_requests
          click_button child_work_item.title

          send_keys :escape

          click_button 'Add issue'

          wait_for_all_requests
        end

        page.refresh
        wait_for_all_requests
      end

      context 'when adding existing work item with fixed dates as children' do
        let_it_be(:child_work_item) do
          create(
            :work_item,
            :issue,
            namespace: work_item.namespace,
            title: 'Existing child issue',
            start_date: 1.day.ago,
            due_date: 1.day.from_now
          )
        end

        it 'rolled up child dates' do
          add_existing_child(child_work_item)

          within work_item_rolledup_dates_selector do
            expect(page).to have_text("Start: #{child_work_item.start_date.to_fs(:medium)}")
            expect(page).to have_text("Due: #{child_work_item.due_date.to_fs(:medium)}")
          end
        end
      end

      context 'when updating child work item dates' do
        it 'rolled up child dates' do
          child_title = 'A child issue'
          add_new_child(title: child_title, start_date: '2020-12-01', due_date: '2020-12-02')

          within work_item_rolledup_dates_selector do
            expect(page).to have_text("Start: Dec 1, 2020")
            expect(page).to have_text("Due: Dec 2, 2020")
          end

          update_child_date(title: child_title, start_date: '2021-01-03', due_date: '2021-01-05')

          within work_item_rolledup_dates_selector do
            expect(page).to have_text('Start: Jan 3, 2021')
            expect(page).to have_text('Due: Jan 5, 2021')
          end
        end
      end

      context 'when removing all children' do
        it 'rolled up child dates' do
          # https://gitlab.com/gitlab-org/gitlab/-/issues/473408
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(107)

          add_new_child(title: 'child issue 1', start_date: '2020-11-01', due_date: '2020-12-02')
          add_new_child(title: 'child issue 2', start_date: '2020-12-01', due_date: '2021-01-02')

          within work_item_rolledup_dates_selector do
            expect(page).to have_text('Start: Nov 1, 2020')
            expect(page).to have_text('Due: Jan 2, 2021')
          end

          within_testid('links-child', text: 'child issue 1') do
            find_by_testid('remove-work-item-link').click
            wait_for_all_requests
          end

          page.refresh
          wait_for_all_requests
          within work_item_rolledup_dates_selector do
            expect(page).to have_text('Start: Dec 1, 2020')
            expect(page).to have_text('Due: Jan 2, 2021')
          end

          within_testid('links-child', text: 'child issue 2') do
            find_by_testid('remove-work-item-link').click
            wait_for_all_requests
          end

          page.refresh
          wait_for_all_requests
          within work_item_rolledup_dates_selector do
            expect(page).to have_text('Start: None')
            expect(page).to have_text('Due: None')
          end
        end
      end

      context 'when child has a milestone' do
        let_it_be_with_reload(:milestone) do
          create(
            :milestone,
            group: work_item.namespace,
            start_date: 1.day.ago,
            due_date: 1.day.from_now
          )
        end

        let_it_be(:child_work_item) do
          create(
            :work_item,
            :issue,
            namespace: work_item.namespace,
            title: 'Existing child issue',
            milestone: milestone
          )
        end

        it 'rolled up child dates' do
          add_existing_child(child_work_item)

          within work_item_rolledup_dates_selector do
            expect(page).to have_text("Start: #{milestone.start_date.to_fs(:medium)}")
            expect(page).to have_text("Due: #{milestone.due_date.to_fs(:medium)}")
          end
        end

        context 'when milestone dates are changed' do
          it 'rolled up child dates' do
            add_existing_child(child_work_item)

            within work_item_rolledup_dates_selector do
              expect(page).to have_text("Start: #{milestone.start_date.to_fs(:medium)}")
              expect(page).to have_text("Due: #{milestone.due_date.to_fs(:medium)}")
            end

            visit edit_group_milestone_path(group, milestone)
            page.within '.milestone-form' do
              fill_in 'milestone_start_date', with: '2016-11-16'
              fill_in 'milestone_due_date', with: '2016-12-16'
              click_button "Save changes"
              wait_for_all_requests
            end

            visit work_items_path
            wait_for_all_requests

            within work_item_rolledup_dates_selector do
              expect(page).to have_text("Start: Nov 16, 2016")
              expect(page).to have_text("Due: Dec 16, 2016")
            end
          end
        end
      end
    end
  end
end
