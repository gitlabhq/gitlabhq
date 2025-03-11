# frozen_string_literal: true
require "test_helper"

class DashboardApplicationControllerTest < ActionDispatch::IntegrationTest
  def test_it_calls_on_load_hook
    assert_equal true, GraphQL::Dashboard::ApplicationController.hook_was_called?
  end
end
