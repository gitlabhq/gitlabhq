# frozen_string_literal: true
require "test_helper"

class DashboardStaticsControllerTest < ActionDispatch::IntegrationTest
  def test_it_serves_assets
    get graphql_dashboard.static_path("dashboard.css")
    assert_includes response.body, "#header-icon {"
    assert_equal response.headers["Cache-Control"], "max-age=31556952, public"
  end

  def test_it_responds_404_for_others
    get graphql_dashboard.static_path("other.rb")
    assert_equal 404, response.status

    assert_raises ActionController::UrlGenerationError do
      graphql_dashboard.static_path("invalid~char.js")
    end

    get graphql_dashboard.static_path("invalid-char.js").sub("-char", "~char")
    assert_equal 404, response.status
  end
end
