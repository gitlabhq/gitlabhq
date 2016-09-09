module WaitForVueResource
  def wait_for_vue_resource(spinner: true)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('Vue.activeResources').zero?
    end

    if spinner
      expect(page).not_to have_selector('.fa-spinner')
    end
  end
end
