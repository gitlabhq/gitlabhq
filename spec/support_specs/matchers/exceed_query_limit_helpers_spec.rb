# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExceedQueryLimitHelpers do
  before do
    stub_const('TestQueries', Class.new(ActiveRecord::Base))
    stub_const('TestMatcher', Class.new)

    TestQueries.class_eval do
      self.table_name = 'schema_migrations'
    end

    TestMatcher.class_eval do
      include ExceedQueryLimitHelpers

      def expected
        ActiveRecord::QueryRecorder.new do
          2.times { TestQueries.count }
        end
      end
    end
  end

  it 'does not contain marginalia annotations' do
    test_matcher = TestMatcher.new
    test_matcher.verify_count do
      2.times { TestQueries.count }
      TestQueries.first
    end

    aggregate_failures do
      expect(test_matcher.log_message)
        .to match(%r{ORDER BY.*#{TestQueries.table_name}.*LIMIT 1})
      expect(test_matcher.log_message)
        .not_to match(%r{\/\*.*correlation_id.*\*\/})
    end
  end
end
