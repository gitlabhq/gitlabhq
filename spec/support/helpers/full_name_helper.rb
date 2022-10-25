# frozen_string_literal: true

module FullNameHelper
  def full_name(first_name, last_name)
    "#{first_name} #{last_name}"
  end
end

FullNameHelper.prepend_mod
