# frozen_string_literal: true

module WorkItemsHelpers
  include ListboxHelpers

  # Listbox helpers
  def select_work_item_type(type)
    select type.to_s.capitalize, from: 'Type'
  end

  def select_namespace(default_namespace, namespace)
    click_button default_namespace
    select_listbox_item namespace
  end

  def add_labels_on_bulk_edit(items = [])
    select_items_from_dropdown(items, 'Select labels', 'bulk-edit-add-labels')
  end

  def remove_labels_on_bulk_edit(items = [])
    select_items_from_dropdown(items,  'Select labels', 'bulk-edit-remove-labels')
  end

  def select_parent_on_bulk_edit(parent_title)
    select_items_from_dropdown([parent_title], 'Select parent', 'bulk-edit-parent')
  end

  def select_no_parent_on_bulk_edit
    select_items_from_dropdown(['No parent'], 'Select parent', 'bulk-edit-parent')
  end

  def search_parent_on_bulk_edit(search_term)
    within_testid('bulk-edit-parent') do
      click_button 'Select parent'
      wait_for_requests
      fill_in 'Search', with: search_term
      wait_for_requests
    end
  end

  def click_parent_bulk_edit_dropdown
    within_testid('bulk-edit-parent') do
      click_button 'Select parent'
      wait_for_requests
    end
  end

  def select_items_from_dropdown(items, listbox_name, testid)
    within_testid(testid) do
      click_button listbox_name
      wait_for_requests

      items.each do |item|
        select_listbox_item item
      end
    end
    close_dropdown
  end

  def close_dropdown
    # The listbox is hiding UI elements, click on body
    page.send_keys(:escape)
  end

  # Textbox helpers
  def fill_work_item_title(title)
    find_by_testid('work-item-title-input').send_keys(title)
  end

  def fill_work_item_description(description)
    fill_in _('Description'), with: description
  end

  # Work item widget helpers
  def assign_work_item_to_yourself
    within_testid 'work-item-assignees' do
      click_button 'assign yourself'
    end
  end

  def set_work_item_label(label_title)
    within_testid 'work-item-labels' do
      click_button 'Edit'
      select_listbox_item(label_title)

      close_dropdown
    end
  end

  def set_work_item_milestone(milestone_title)
    within_testid 'work-item-milestone' do
      click_button 'Edit'
      select_listbox_item(milestone_title)
    end
  end

  # Action helpers
  def create_work_item_with_type(type)
    click_button "Create #{type}"
  end

  def click_bulk_edit
    click_button 'Bulk edit'
  end

  def click_update_selected
    click_button 'Update selected'
  end

  def check_work_items(items = [])
    # Select work items from the list
    items.each do |item|
      check item
    end
  end

  # Assertion helpers
  def expect_work_item_widgets(widget_names)
    widget_names.each do |widget|
      expect(page).to have_selector("[data-testid=\"#{widget}\"]")
    end
  end

  def find_work_item_element(work_item_id)
    find("#issuable_#{work_item_id}")
  end

  # drawer helpers
  def close_drawer
    find('[data-testid="work-item-drawer"] .gl-drawer-close-button').click
    wait_for_all_requests
  end

  # time tracking
  def add_estimate(estimate)
    click_button 'estimate'
    within_testid 'set-time-estimate-modal' do
      fill_in 'Estimate', with: estimate
      click_button 'Save'
    end
  end

  def add_time_entry(time, summary = '')
    click_button 'Add time entry'
    within_testid 'create-timelog-modal' do
      fill_in 'Time spent', with: time
      fill_in 'Summary', with: summary
      click_button 'Save'
    end
  end
end
