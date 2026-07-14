# frozen_string_literal: true

module ListboxHelpers
  def select_from_listbox(text, from:, exact_item_text: false)
    toggle_listbox(from)
    select_listbox_item(text, exact_text: exact_item_text)
  end

  def select_first_listbox_item(text, exact_text: false)
    find('.gl-new-dropdown-item[role="option"]', match: :first, text: text, exact_text: exact_text).click
  end

  def select_create_from_listbox(create_text, from:)
    click_button from
    click_button create_text
  end

  def select_listbox_item(text, exact_text: false)
    find('.gl-new-dropdown-item[role="option"]', text: text, exact_text: exact_text).click
  end

  def select_disclosure_dropdown_item(text, exact_text: false)
    find('.gl-new-dropdown-item', text: text, exact_text: exact_text).click
  end

  def toggle_listbox(text = nil)
    find('.gl-new-dropdown-toggle:not(.disabled)', text: text).click
  end

  def expect_listbox_item(text)
    expect(page).to have_css('.gl-new-dropdown-item[role="option"]', text: text)
  end

  def expect_no_listbox_item(text)
    expect(page).not_to have_css('.gl-new-dropdown-item[role="option"]', text: text)
  end

  def expect_listbox_items(items)
    expect(page).to have_selector('.gl-new-dropdown-item[role="option"]', count: items.size)
    items.each { |item| expect_listbox_item(item) }
  end

  def expect_listbox_role_names(roles)
    expect(page).to have_selector('[data-testid="role-name"]', count: roles.size)
    roles.each do |role|
      expect(page).to have_selector('[data-testid="role-name"]', text: role)
    end
  end

  def expect_listbox_role_description(role_name, description)
    item = find('.gl-new-dropdown-item[role="option"]', text: role_name)
    expect(item).to have_css('[data-testid="role-description"]', text: description)
  end
end
