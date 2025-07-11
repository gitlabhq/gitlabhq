# frozen_string_literal: true

module WorkItemsHelpers
  def select_work_item_type(type)
    select type.to_s.capitalize, from: 'Type'
  end

  def fill_work_item_title(title)
    find_by_testid('work-item-title-input').send_keys(title)
  end

  def fill_work_item_description(description)
    fill_in _('Description'), with: description
  end

  def assign_work_item_to_yourself
    within_testid 'work-item-assignees' do
      click_button 'assign yourself'
    end
  end

  def set_work_item_label(label_title)
    within_testid 'work-item-labels' do
      click_button 'Edit'
      select_listbox_item(label_title)
      # The listbox is hiding Apply button,
      # click listbox to dismiss and apply label
      find_field('Search').send_keys(:escape)
    end
  end

  def set_work_item_milestone(milestone_title)
    within_testid 'work-item-milestone' do
      click_button 'Edit'
      select_listbox_item(milestone_title)
    end
  end

  def create_work_item_with_type(type)
    click_button "Create #{type}"
  end

  def expect_work_item_widgets(widget_names)
    widget_names.each do |widget|
      expect(page).to have_selector("[data-testid=\"#{widget}\"]")
    end
  end
end
