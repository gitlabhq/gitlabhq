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
  end
end

Ci::Partitionable::Testing::PARTITIONABLE_MODELS.each do |klass|
  next if klass == 'Ci::Pipeline'

  model = klass.safe_constantize

  model.include(PartitioningTesting::CascadeCheck)
end
