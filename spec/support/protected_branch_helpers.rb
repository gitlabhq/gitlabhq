module ProtectedBranchHelpers
  def set_allowed_to(operation, option = 'Masters', form: '.js-new-protected-branch')
    within form do
      find(".js-allowed-to-#{operation}").trigger('click')
      wait_for_requests

      Array(option).each { |opt| click_on(opt) }

      find(".js-allowed-to-#{operation}").trigger('click') # needed to submit form in some cases
    end
  end

  def set_protected_branch_name(branch_name)
    find(".js-protected-branch-select").trigger('click')
    find(".dropdown-input-field").set(branch_name)
    click_on("Create wildcard #{branch_name}")
  end
end
