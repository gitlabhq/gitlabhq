# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Observable, feature_category: :database do
  let(:test_class) do
    Class.new do
      include Gitlab::Database::BackgroundOperation::Observable

      def id
        [1, 100]
      end

      def job_class_name
        'TestJobClass'
      end

      def table_name
        'test_table'
      end

      def column_name
        'test_column'
      end
    end
  end

  subject(:instance) { test_class.new }

  describe '#prometheus_labels' do
    it 'returns a hash with migration_id and migration_identifier' do
      expect(instance.prometheus_labels).to(
        include(
          migration_id: '1/100',
          migration_identifier: 'TestJobClass/test_table.test_column'
        )
      )
    end
  end
end
