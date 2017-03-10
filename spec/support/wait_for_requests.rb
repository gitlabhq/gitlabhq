module WaitForRequests
  extend self

  # This is inspired by http://www.salsify.com/blog/engineering/tearing-capybara-ajax-tests
  def wait_for_requests_complete
    stop_client
    Gitlab::Testing::RequestBlockerMiddleware.block_requests!
    wait_for('pending AJAX requests complete') do
      Gitlab::Testing::RequestBlockerMiddleware.num_active_requests.zero?
    end
  ensure
    Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
  end

  # Navigate away from the current page which will prevent any new requests from being started
  def stop_client
    page.execute_script %Q{
      window.location = "about:blank";
    }
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
end

RSpec.configure do |config|
  config.after(:each, :js) do
    wait_for_requests_complete
  end
end
