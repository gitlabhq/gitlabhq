# frozen_string_literal: true

# Catches a system hook SELECT without an organization filter, even when its result never reaches
# the response. Base `WebHook` lookups have no type filter and are skipped, so a path that switches
# to one captures no system hook query and fails the empty-capture guard.
module SystemHookOrganizationScopeMatcher
  SQL_ANNOTATION = %r{\s*/\*.*?\*/}m
  SELECT_QUERY = /\A[\s(]*(?:SELECT|WITH)\b/i
  SYSTEM_HOOK_FILTER = /\bweb_hooks"?\s*\.\s*"?type"?\s*(?:=\s*'SystemHook'|IN\s*\([^)]*'SystemHook')/i
  # Full-row SELECTs list `organization_id` as a column, so only `=` and `IN (` count as a filter.
  ORGANIZATION_FILTER = /\bweb_hooks"?\s*\.\s*"?organization_id"?\s*(?:=|IN\s*\()/i

  module_function

  def system_hook_queries(queries)
    queries.filter_map do |raw|
      sql = strip_annotations(raw)

      { raw: raw, sql: sql } if system_hook_query?(sql)
    end
  end

  def unscoped_queries(system_hook_queries)
    system_hook_queries.reject { |query| organization_filter?(query[:sql]) }
  end

  def system_hook_query?(sql)
    sql.match?(SELECT_QUERY) && sql.match?(SYSTEM_HOOK_FILTER)
  end

  # Checks the whole statement, so a UNION or an OR with one scoped branch still passes.
  def organization_filter?(sql)
    sql.match?(ORGANIZATION_FILTER)
  end

  def strip_annotations(sql)
    sql.gsub(SQL_ANNOTATION, '')
  end
end

RSpec::Matchers.define :query_system_hooks_without_organization_id do
  supports_block_expectations

  def record_queries(block)
    @recorder = ActiveRecord::QueryRecorder.new(&block)
    @system_hook_queries = SystemHookOrganizationScopeMatcher.system_hook_queries(@recorder.log)
    @unscoped = SystemHookOrganizationScopeMatcher.unscoped_queries(@system_hook_queries)
  end

  def describe_query(query)
    line, method = @recorder.get_sql_source(query[:raw])

    return query[:sql] if [line, method] == ActiveRecord::QueryRecorder::UNKNOWN

    "#{line}:in '#{method}'\n#{query[:sql]}"
  end

  def nothing_captured_message
    "no SELECT on `web_hooks` filtered on `type = 'SystemHook'` was captured in the block, so " \
      "the assertion would pass vacuously. Check the block runs the code path. Results may be " \
      "memoized, or the lookup may go through the base `WebHook` class"
  end

  match do |_block|
    raise ArgumentError, '`query_system_hooks_without_organization_id` only supports `not_to`'
  end

  match_when_negated do |block|
    record_queries(block)
    @system_hook_queries.any? && @unscoped.none?
  end

  failure_message_when_negated do
    if @system_hook_queries.none?
      nothing_captured_message
    else
      "expected every SELECT on `web_hooks` filtered on `type = 'SystemHook'` to also filter on " \
        "`\"web_hooks\".\"organization_id\"`, but #{@unscoped.size} of #{@system_hook_queries.size} " \
        "did not:\n\n#{@unscoped.map { |query| describe_query(query) }.join("\n\n")}"
    end
  end
end
