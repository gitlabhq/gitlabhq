module WaitForAjax
  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def javascript_test?
    [:selenium, :webkit, :chrome, :poltergeist].include?(Capybara.current_driver)
  end
end
