# frozen_string_literal: true

module StubProjectStudio
  # This can't run in a `before_all` block as long as we set all feature flags to be `false` in the `spec_helper`
  def enable_project_studio!(user)
    stub_feature_flags(paneled_view: user)

    user.new_ui_enabled = true
  end

  def dismiss_welcome_banner_if_present(page)
    modal_dismiss_button_selector = '#dap_welcome_modal header button[aria-label="Close"]'

    return unless page.respond_to?(:has_selector?)

    return unless page.has_selector?(modal_dismiss_button_selector, wait: 0)

    page.find(modal_dismiss_button_selector).click

  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    # Element became stale between finding and clicking - likely already dismissed
  end
end
