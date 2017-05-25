require_relative './wait_for_requests'

module WaitForRequests
  extend self

  # This is inspired by http://www.salsify.com/blog/engineering/tearing-capybara-ajax-tests
  def block_and_wait_for_requests_complete
    Gitlab::Testing::RequestBlockerMiddleware.block_requests!
    wait_for('pending requests complete') do
      Gitlab::Testing::RequestBlockerMiddleware.num_active_requests.zero?
    end
  ensure
    Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
  end

  def wait_for_requests
    wait_for('JS requests') { finished_all_requests? }
  end

  private

  def finished_all_requests?
    return true unless javascript_test?

    finished_all_ajax_requests? &&
      finished_all_vue_resource_requests?
  end

  # Waits until the passed block returns true
  def wait_for(condition_name, max_wait_time: Capybara.default_max_wait_time, polling_interval: 0.01)
    wait_until = Time.now + max_wait_time.seconds
    loop do
      break if yield
      if Time.now > wait_until
        raise "Condition not met: #{condition_name}"
      else
        sleep(polling_interval)
      end
    end
  end

  def finished_all_vue_resource_requests?
    page.evaluate_script('window.activeVueResources || 0').zero?
  end

  def finished_all_ajax_requests?
    return true if page.evaluate_script('typeof jQuery === "undefined"')

    page.evaluate_script('jQuery.active').zero?
  end

  def javascript_test?
    Capybara.current_driver == Capybara.javascript_driver
  end
end

RSpec.configure do |config|
  config.after(:each, :js) do
    block_and_wait_for_requests_complete
  end
end
