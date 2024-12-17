# frozen_string_literal: true

RSpec.shared_examples 'work items rolled up dates' do
  include WorkItemFeedbackHelpers

  let(:work_item_rolledup_dates_selector) { '[data-testid="work-item-rolledup-dates"]' }
  let(:work_item_start_due_dates_selector) { '[data-testid="work-item-start-due-dates"]' }
  let(:work_item_milestone_selector) { '[data-testid="work-item-milestone"]' }

  def expect_sync_to_epic
    dates_source = work_item.dates_source
    epic = work_item.synced_epic

    expect(dates_source.start_date_is_fixed).to eq(epic.start_date_is_fixed)
    expect(dates_source.start_date_fixed).to eq(epic.start_date_fixed)
    expect(dates_source.due_date_is_fixed).to eq(epic.due_date_is_fixed)
    expect(dates_source.due_date_fixed).to eq(epic.due_date_fixed)
    expect(dates_source.start_date_sourcing_milestone_id).to eq(epic.start_date_sourcing_milestone_id)
    expect(dates_source.due_date_sourcing_milestone_id).to eq(epic.due_date_sourcing_milestone_id)
    expect(dates_source.start_date_sourcing_work_item_id).to eq(epic.start_date_sourcing_epic&.issue_id)
    expect(dates_source.due_date_sourcing_work_item_id).to eq(epic.due_date_sourcing_epic&.issue_id)
  end

  it_behaves_like 'work items rolled up dates in drawer'

  context 'when feature flag is enabled' do
    before do
      stub_licensed_features(epics: true, subepics: true, epic_colors: true)

      page.refresh
      wait_for_all_requests

      close_work_item_feedback_popover_if_present
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

        within_testid('work-item-drawer') do
          find_and_click_edit work_item_rolledup_dates_selector
          # set empty value before the value to ensure
          # the current value don't mess with the new value input
          fill_in 'Start', with: ""
          fill_in 'Start', with: start_date
          fill_in 'Due', with: "" # ensure to reset the input first to avoid wrong date values
          fill_in 'Due', with: due_date

          find_by_testid('close-icon').click
          wait_for_all_requests
        end

        page.refresh
        wait_for_all_requests
      end

      def add_new_child(title:, milestone: nil, start_date: nil, due_date: nil)
        within_testid('work-item-tree') do
          click_button 'Add'
          click_button 'New epic'
          wait_for_all_requests

          fill_in 'Add a title', with: title
          click_button 'Create epic'
          wait_for_all_requests
        end

        if start_date.present? || due_date.present?
          update_child_date(title: title, start_date: start_date, due_date: due_date)
        end

        update_child_milestone(title: title, milestone: milestone) if milestone.present?
      end

      def add_existing_child(child_work_item, type)
        within_testid('work-item-tree') do
          click_button 'Add'
          click_button "Existing #{type}"

          find_by_testid('work-item-token-select-input').set(child_work_item.title)
          wait_for_all_requests
          click_button child_work_item.title

          send_keys :escape

          click_button "Add #{type}"

          wait_for_all_requests
        end

        page.refresh
        wait_for_all_requests
      end

      context 'when adding existing work item with fixed dates as children' do
        let_it_be(:child_work_item) do
          create(
            :work_item,
            :epic_with_legacy_epic,
            namespace: work_item.namespace,
            title: 'Existing child issue',
            start_date: 1.day.ago,
            due_date: 1.day.from_now
          )
        end

        it 'rolled up child dates' do
          add_existing_child(child_work_item, :epic)

          within work_item_rolledup_dates_selector do
            expect(page).to have_text("Start: #{child_work_item.start_date.to_fs(:medium)}")
            expect(page).to have_text("Due: #{child_work_item.due_date.to_fs(:medium)}")
          end

          expect_sync_to_epic
        end
      end

      context 'when updating child work item dates' do
        it 'rolled up child dates' do
          # https://gitlab.com/gitlab-org/gitlab/-/issues/473408
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(105)

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

          expect_sync_to_epic
        end
      end

      context 'when removing all children' do
        it 'rolled up child dates' do
          # https://gitlab.com/gitlab-org/gitlab/-/issues/473408
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(120)

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

          expect_sync_to_epic
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
          # https://gitlab.com/gitlab-org/gitlab/-/issues/473408
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(101)

          add_existing_child(child_work_item, :issue)

          within work_item_rolledup_dates_selector do
            expect(page).to have_text("Start: #{milestone.start_date.to_fs(:medium)}")
            expect(page).to have_text("Due: #{milestone.due_date.to_fs(:medium)}")
          end

          expect_sync_to_epic
        end

        context 'when milestone dates are changed' do
          it 'rolled up child dates' do
            add_existing_child(child_work_item, :issue)

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

            expect_sync_to_epic
          end
        end
      end
    end
  end
end
