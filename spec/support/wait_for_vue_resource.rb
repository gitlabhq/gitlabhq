module WaitForVueResource
  def wait_for_vue_resource(spinner: true)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('window.activeVueResources').zero?
    end
  end

  def finished_all_vue_resource_requests?
    return true unless javascript_test?

    page.evaluate_script('window.activeVueResources || 0').zero?
  end

  def javascript_test?
    Capybara.current_driver == Capybara.javascript_driver
  end
end
