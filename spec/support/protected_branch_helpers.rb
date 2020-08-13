# frozen_string_literal: true

module ProtectedBranchHelpers
  def set_allowed_to(operation, option = 'Maintainers', form: '.js-new-protected-branch')
    within form do
      select_elem = find(".js-allowed-to-#{operation}")
      select_elem.click

      wait_for_requests

      within('.dropdown-content') do
        Array(option).each { |opt| click_on(opt) }
      end

      # Enhanced select is used in EE, therefore an extra click is needed.
      select_elem.click if select_elem['aria-expanded'] == 'true'
    end
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
end
