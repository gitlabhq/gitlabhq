# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::QueryRecorder do
  before do
    stub_const('TestQueries', Class.new(ActiveRecord::Base))

    TestQueries.class_eval do
      self.table_name = 'schema_migrations'
    end
  end

  describe 'printing to the log' do
    let(:backtrace) { %r{QueryRecorder backtrace:  --> (\w+/)*\w+\.rb:\d+:in `.*'} }
    let(:duration_line) { %r{QueryRecorder DURATION:  --> \d+\.\d+} }

    def expect_section(query, lines)
      query_lines = lines.take(query.size)

      # the query comes first
      expect(query_lines).to match(query)

      # followed by the duration
      expect(lines[query.size]).to match(duration_line)

      # and then one or more lines of backtrace
      backtrace_lines = lines.drop(query.size + 1).take_while { |line| line.match(backtrace) }
      expect(backtrace_lines).not_to be_empty

      # Advance to the next section
      lines.drop(query.size + 1 + backtrace_lines.size)
    end

    it 'prints SQL, duration and backtrace, all prefixed with QueryRecorder', :aggregate_failures do
      io = StringIO.new

      control = ActiveRecord::QueryRecorder.new(log_file: io, query_recorder_debug: true) do
        TestQueries.count
        TestQueries.first
        TestQueries.where(<<~FRAGMENT).to_a # tests multi-line SQL
          version = 'foo'
           OR
          version = 'bar'
        FRAGMENT
      end

      query_a = start_with(%q[QueryRecorder SQL:  --> SELECT COUNT(*) FROM "schema_migrations"])

      query_b = start_with(%q(QueryRecorder SQL:  --> SELECT "schema_migrations".* FROM "schema_migrations" ORDER BY "schema_migrations"."version" ASC LIMIT 1))

      query_c_a = eq(%q[QueryRecorder SQL:  --> SELECT "schema_migrations".* FROM "schema_migrations" WHERE (version = 'foo'])
      query_c_b = eq(%q(QueryRecorder SQL:  -->  OR))
      query_c_c = eq(%q(QueryRecorder SQL:  --> version = 'bar'))
      query_c_d = start_with("QueryRecorder SQL:  --> )")

      expect(control.count).to eq(3)

      lines = io.string.lines.map(&:chomp)

      expect(lines).to all(start_with('QueryRecorder'))
      lines = expect_section([query_a], lines)
      lines = expect_section([query_b], lines)
      lines = expect_section([query_c_a, query_c_b, query_c_c, query_c_d], lines)

      expect(lines).to be_empty
    end
  end

  it 'includes duration information' do
    control = ActiveRecord::QueryRecorder.new do
      TestQueries.count
      TestQueries.first
    end

    expect(control.count).to eq(2)
    expect(control.data.values.flat_map { _1[:durations] }).to match([be > 0, be > 0])
  end

  describe 'detecting the right number of calls and their origin' do
    let(:control) do
      ActiveRecord::QueryRecorder.new query_recorder_debug: true do
        2.times { TestQueries.count }
        TestQueries.first
      end
    end

    it 'detects two separate queries' do
      # Check #find_query
      expect(control.find_query(/.*/, 0).size)
        .to eq(control.data.keys.size)
      # Ensure exactly 2 COUNT queries were detected
      expect(control.occurrences_by_line_method.last[1][:occurrences]
               .count { |str| str.start_with?('SELECT COUNT') }).to eq(2)
      # Ensure exactly 1 LIMIT 1 (#first)
      expect(control.occurrences_by_line_method.first[1][:occurrences]
               .count { |str| str.match(/ORDER BY.*#{TestQueries.table_name}.*LIMIT 1/) }).to eq(1)

      # Ensure 3 DB calls overall were executed
      expect(control.log.size).to eq(3)
      # Ensure memoization value match the raw value above
      expect(control.count).to eq(control.log.size)
      # Ensure we have two sources of queries
      expect(control.data.keys.size).to eq(2)
    end
  end
end
