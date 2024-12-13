# frozen_string_literal: true

require_relative 'protected_branch_helpers'

module ProtectedTagHelpers
  include ::ProtectedBranchHelpers

  def set_allowed_to(operation, option = 'Maintainers', form: '.new-protected-tag')
    super
  end

  def set_protected_tag_name(tag_name)
    find('.js-protected-tag-select').click
    find('.dropdown-input-field').set(tag_name)
    click_on("Create wildcard #{tag_name}")
    find('.protected-tags-dropdown .dropdown-menu', visible: false)
  end

  def click_on_protect(form: '.new-protected-tag')
    super
  end
end
