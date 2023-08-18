# frozen_string_literal: true

RSpec.configure do |config|
  config.include ::Ci::PartitioningTesting::PartitionIdentifiers

  config.around(:each, :ci_partitionable) do |example|
    ::Ci::PartitioningTesting::SchemaHelpers.with_routing_tables do
      example.run
    end
  end

  config.before(:all) do
    ::Ci::PartitioningTesting::SchemaHelpers.setup
  end

  config.after(:all) do
    ::Ci::PartitioningTesting::SchemaHelpers.teardown
  end
end
