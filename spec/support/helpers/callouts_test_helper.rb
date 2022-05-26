# frozen_string_literal: true

module CalloutsTestHelper
  def callouts_trials_link_path
    '/-/trial_registrations/new?glm_content=gold-callout&glm_source=gitlab.com'
  end
end

CalloutsTestHelper.prepend_mod
