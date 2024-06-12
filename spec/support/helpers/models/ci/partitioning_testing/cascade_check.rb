# frozen_string_literal: true

module PartitioningTesting
  module CascadeCheck
    extend ActiveSupport::Concern

    included do
      after_create :check_partition_cascade_value
    end

    def check_partition_cascade_value
      raise 'Partition value not found' unless partition_scope_value

      return if partition_id == partition_scope_value

      raise "partition_id was expected to equal #{partition_scope_value} but it was #{partition_id}."
    end

    class_methods do
      # Allowing partition callback to be used with BulkInsertSafe
      def _bulk_insert_callback_allowed?(name, args)
        super || (args.first == :after && args.second == :check_partition_cascade_value)
      end
    end
  end
end

Ci::Partitionable::Testing.partitionable_models.each do |klass|
  next if klass == 'Ci::Pipeline'

  model = klass.safe_constantize
  next unless model

  model.include(PartitioningTesting::CascadeCheck)
end
