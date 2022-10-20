# frozen_string_literal: true

module PartitioningTesting
  module CascadeCheck
    extend ActiveSupport::Concern

    included do
      after_create :check_partition_cascade_value
    end

    def check_partition_cascade_value
      raise 'Partition value not found' unless partition_scope_value
      raise 'Default value detected' if partition_id == 100

      return if partition_id == partition_scope_value

      raise "partition_id was expected to equal #{partition_scope_value} but it was #{partition_id}."
    end
  end

  module DefaultPartitionValue
    extend ActiveSupport::Concern

    class_methods do
      def current_partition_value
        current = super

        if current == 100
          54321
        else
          current
        end
      end
    end
  end
end

Ci::Partitionable::Testing::PARTITIONABLE_MODELS.each do |klass|
  model = klass.safe_constantize

  if klass == 'Ci::Pipeline'
    model.prepend(PartitioningTesting::DefaultPartitionValue)
  else
    model.include(PartitioningTesting::CascadeCheck)
  end
end
