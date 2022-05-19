# frozen_string_literal: true

module SaasTestHelper
  def get_next_url
    "https://next.gitlab.com"
  end
end

SaasTestHelper.prepend_mod
