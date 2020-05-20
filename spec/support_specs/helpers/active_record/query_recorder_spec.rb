# frozen_string_literal: true

require 'spec_helper'

describe ActiveRecord::QueryRecorder do
  before do
    stub_const('TestQueries', Class.new(ActiveRecord::Base))

    TestQueries.class_eval do
      self.table_name = 'schema_migrations'
    end
  end

  describe 'detecting the right number of calls and their origin' do
    it 'detects two separate queries' do
      control = ActiveRecord::QueryRecorder.new query_recorder_debug: true do
        2.times { TestQueries.count }
        TestQueries.first
      end

      # Check #find_query
      expect(control.find_query(/.*/, 0).size)
        .to eq(control.data.keys.size)
      # Ensure exactly 2 COUNT queries were detected
      expect(control.occurrences_by_line_method.last[1][:occurrences]
               .find_all {|i| i.match(/SELECT COUNT/) }.count).to eq(2)
      # Ensure exactly 1 LIMIT 1 (#first)
      expect(control.occurrences_by_line_method.first[1][:occurrences]
               .find_all { |i| i.match(/ORDER BY.*#{TestQueries.table_name}.*LIMIT 1/) }.count).to eq(1)

      # Ensure 3 DB calls overall were executed
      expect(control.log.size).to eq(3)
      # Ensure memoization value match the raw value above
      expect(control.count).to eq(control.log.size)
      # Ensure we have only two sources of queries
      expect(control.data.keys.size).to eq(1)
    end
  end
end
