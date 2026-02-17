# frozen_string_literal: true

module WorkItemsOnboardingHelpers
  def close_work_items_onboarding_modal_if_present
    return unless page.has_css?("[data-testid='work-items-onboarding-modal']")

    page.within("[data-testid='work-items-onboarding-modal']") do
      page.find("[data-testid='close-icon']").click
    end
  end
end
