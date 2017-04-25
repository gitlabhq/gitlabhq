module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    return true unless javascript_test?
    return true if page.evaluate_script('typeof jQuery === "undefined"')

    page.evaluate_script('jQuery.active').zero?
  end

  def javascript_test?
    Capybara.current_driver == Capybara.javascript_driver
  end
end
