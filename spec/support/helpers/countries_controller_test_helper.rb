# frozen_string_literal: true

module CountriesControllerTestHelper
  def world_deny_list
    ::World::DENYLIST + ::World::JH_MARKET
  end
end

CountriesControllerTestHelper.prepend_mod
