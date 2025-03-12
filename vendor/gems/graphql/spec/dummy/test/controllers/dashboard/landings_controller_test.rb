# frozen_string_literal: true
require "test_helper"

class DashboardLandingsControllerTest < ActionDispatch::IntegrationTest
  def test_it_shows_a_landing_page
    get graphql_dashboard.root_path
    assert_includes response.body, "Welcome to the GraphQL-Ruby Dashboard"
  end

  def test_it_shows_version_and_schema_info
    get graphql_dashboard.root_path
    assert_includes response.body, "GraphQL-Ruby v#{GraphQL::VERSION}"
    assert_includes response.body, "<code>DummySchema</code>"
    get graphql_dashboard.root_path, params: { schema: "NotInstalledSchema" }
    assert_includes response.body, "<code>NotInstalledSchema</code>"
  end
end
