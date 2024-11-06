# frozen_string_literal: true

module WorkItemFeedbackHelpers
  def close_work_item_feedback_popover_if_present
    return unless page.has_css?("[data-testid='work-item-feedback-popover']")

    page.within("[data-testid='work-item-feedback-popover']") do
      page.find("[data-testid='close-button']").click
    end
  end
end
