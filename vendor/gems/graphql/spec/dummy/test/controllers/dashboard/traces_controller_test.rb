# frozen_string_literal: true
require "test_helper"

class DashboardTracesControllerTest < ActionDispatch::IntegrationTest
  def teardown
    DummySchema.detailed_trace.delete_all_traces
  end

  def test_it_renders_not_installed
    get graphql_dashboard.traces_path, params: { schema: "NotInstalledSchema" }
    assert_includes response.body, "Traces aren't installed yet"
    assert_includes response.body, "<code>NotInstalledSchema</code>"
  end

  def test_it_renders_blank_state
    get graphql_dashboard.traces_path
    assert_includes response.body, "No traces saved yet."
    assert_includes response.body, "<code>DummySchema</code>"
  end

  def test_it_renders_trace_listing_with_pagination
    20.times do |n|
      sleep 0.05
      DummySchema.execute("query Query#{n} { str }", context: { profile: true })
    end
    assert_equal 20, DummySchema.detailed_trace.traces.size

    get graphql_dashboard.traces_path, params: { last: 10 }

    assert_includes response.body, "Query19"
    assert_includes response.body, "Query10"
    refute_includes response.body, "Query9"
    last_trace = DummySchema.detailed_trace.traces[9]
    last_ts = last_trace.begin_ms
    assert_includes response.body, "<td>#{Time.at(last_ts / 1000.0).strftime("%Y-%m-%d %H:%M:%S.%L")}</td>"
    assert_includes response.body, "<a class=\"btn btn-outline-primary\" href=\"/dash/traces?before=#{last_ts}&amp;last=10\">Previous &gt;</a>"
    get graphql_dashboard.traces_path, params: { last: 10, before: last_ts }
    assert_includes response.body, "Query9"
    assert_includes response.body, "Query0"
    refute_includes response.body, "Query10"
    very_last_trace = DummySchema.detailed_trace.traces.last
    very_last_ts = very_last_trace.begin_ms
    very_last_td = "<td>#{Time.at(very_last_ts / 1000.0).strftime("%Y-%m-%d %H:%M:%S.%L")}</td>"
    assert_includes response.body, very_last_td
    very_last_previous_link = "<a class=\"btn btn-outline-primary\" href=\"/dash/traces?before=#{very_last_ts}&amp;last=10\">Previous &gt;</a>"
    assert_includes response.body, very_last_previous_link

    # Go beyond last trace:
    get graphql_dashboard.traces_path, params: { last: 11, before: last_ts }
    assert_includes response.body, very_last_td
    refute_includes response.body, very_last_previous_link
  end

  def test_it_deletes_one_trace
    DummySchema.execute("{ str }", context: { profile: true })
    assert_equal 1, DummySchema.detailed_trace.traces.size
    id = DummySchema.detailed_trace.traces.first.id
    delete graphql_dashboard.trace_path(id)
    assert_equal 0, DummySchema.detailed_trace.traces.size
  end

  def test_it_deletes_all_traces
    DummySchema.execute("{ str }", context: { profile: true })
    assert_equal 1, DummySchema.detailed_trace.traces.size
    delete graphql_dashboard.traces_delete_all_path
    assert_equal 0, DummySchema.detailed_trace.traces.size
  end
end
