# frozen_string_literal: true

module Ci
  module PartitioningHelpers
    def stub_current_partition_id(id = Ci::PartitioningTesting::PartitionIdentifiers.ci_testing_partition_id)
      allow(::Ci::Pipeline)
        .to receive(:current_partition_value)
        .and_return(id)
    end
  end
end
