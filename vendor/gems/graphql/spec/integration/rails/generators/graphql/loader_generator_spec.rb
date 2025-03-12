# frozen_string_literal: true
require "spec_helper"
require "generators/graphql/loader_generator"

class GraphQLGeneratorsLoaderGeneratorTest < BaseGeneratorTest
  tests Graphql::Generators::LoaderGenerator

  test "it generates an empty loader by name" do
    run_generator(["RecordLoader"])

    expected_content = <<-RUBY
# frozen_string_literal: true

module Loaders
  class RecordLoader < GraphQL::Batch::Loader
    # Define `initialize` to store grouping arguments, eg
    #
    #     Loaders::RecordLoader.for(group).load(value)
    #
    # def initialize()
    # end

    # `keys` contains each key from `.load(key)`.
    # Find the corresponding values, then
    # call `fulfill(key, value)` or `fulfill(key, nil)`
    # for each key.
    def perform(keys)
    end
  end
end
RUBY

    assert_file "app/graphql/loaders/record_loader.rb", expected_content
  end

  test "it generates a namespaced loader by name" do
    run_generator(["active_record::record_loader"])

    expected_content = <<-RUBY
# frozen_string_literal: true

module Loaders
  class ActiveRecord::RecordLoader < GraphQL::Batch::Loader
    # Define `initialize` to store grouping arguments, eg
    #
    #     Loaders::ActiveRecord::RecordLoader.for(group).load(value)
    #
    # def initialize()
    # end

    # `keys` contains each key from `.load(key)`.
    # Find the corresponding values, then
    # call `fulfill(key, value)` or `fulfill(key, nil)`
    # for each key.
    def perform(keys)
    end
  end
end
RUBY

    assert_file "app/graphql/loaders/active_record/record_loader.rb", expected_content
  end
end
