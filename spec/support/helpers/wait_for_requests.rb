# frozen_string_literal: true

require_relative 'wait_helpers'

module WaitForRequests
  include WaitHelpers
  extend self

  # This is inspired by http://www.salsify.com/blog/engineering/tearing-capybara-ajax-tests
  def block_and_wait_for_requests_complete
    block_requests { wait_for_all_requests }
  end

  # Block all requests inside block with 503 response
  def block_requests
    Gitlab::Testing::RequestBlockerMiddleware.block_requests!
    yield
  ensure
    Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
  end

  # Slow down requests inside block by injecting `sleep 0.2` before each response
  def slow_requests
    Gitlab::Testing::RequestBlockerMiddleware.slow_requests!
    yield
  ensure
    Gitlab::Testing::RequestBlockerMiddleware.allow_requests!
  end

  def block_and_wait_for_action_cable_requests_complete
    block_action_cable_requests { wait_for_action_cable_requests }
  end

  def block_action_cable_requests
    Gitlab::Testing::ActionCableBlocker.block_requests!
    yield
  ensure
    Gitlab::Testing::ActionCableBlocker.allow_requests!
  end

  # Wait for client-side AJAX requests
  def wait_for_requests
    wait_for('JS requests complete', max_wait_time: 2 * Capybara.default_max_wait_time) do
      finished_all_js_requests?
    end
  end

  # Wait for active Rack requests and client-side AJAX requests
  def wait_for_all_requests
    wait_for('pending requests complete') do
      finished_all_rack_requests? &&
        finished_all_js_requests?
    end
  end

  def wait_for_action_cable_requests
    wait_for('Action Cable requests complete') do
      Gitlab::Testing::ActionCableBlocker.num_active_requests == 0
    end
  end

  private

  def finished_all_rack_requests?
    Gitlab::Testing::RequestBlockerMiddleware.num_active_requests == 0
  end

  def finished_all_js_requests?
    return true unless javascript_test?

    finished_all_ajax_requests?
  end

  def finished_all_ajax_requests?
    Capybara
      .page
      .evaluate_script('window.pendingRequests || window.pendingApolloRequests || window.pendingRailsUJSRequests || 0')
      .zero?
  end
end
