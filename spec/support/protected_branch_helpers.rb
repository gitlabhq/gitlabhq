# frozen_string_literal: true

module ProtectedBranchHelpers
  def set_allowed_to(operation, option = 'Maintainers', form: '.js-new-protected-branch')
    within(form) do
      within_select(".js-allowed-to-#{operation}:not([disabled])") do
        Array(option).each { |opt| click_on(opt) }
      end
    end
  end

  def show_add_form
    click_button 'Add protected branch'
  end

  def set_protected_branch_name(branch_name)
    find('.js-protected-branch-select').click
    find('.dropdown-input-field').set(branch_name)
    click_on("Create wildcard #{branch_name}")
  end

  def set_defaults
    set_allowed_to('merge')
    set_allowed_to('push')
  end

  def click_on_protect
    click_on "Protect"
    wait_for_requests
  end

  def within_select(selector, &block)
    select_input = find(selector)
    select_input.click
    wait_for_requests

    within('.dropdown .dropdown-menu.show', &block)

    # Enhanced select is used in EE, therefore an extra click is needed.
    select_input.click if select_input['aria-expanded'] == 'true'
  end
end
