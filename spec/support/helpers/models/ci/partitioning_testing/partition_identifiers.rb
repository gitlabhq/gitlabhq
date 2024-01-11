# frozen_string_literal: true

module Ci
  module PartitioningTesting
    module PartitionIdentifiers
      module_function

      def ci_testing_partition_id
        99999
      end

      def ci_testing_partition_id_for_check_constraints
        101
      end
    end
  end
end
