# frozen_string_literal: true

require 'knapsack'

module KnapsackEnv
  class RSpecContextAdapter < Knapsack::Adapters::RSpecAdapter
    def bind_time_tracker
      ::RSpec.configure do |config|
        # Original version starts timer in `config.prepend_before(:each) do`
        # https://github.com/KnapsackPro/knapsack/blob/v1.17.0/lib/knapsack/adapters/rspec_adapter.rb#L9
        config.prepend_before(:context) do
          Knapsack.tracker.start_timer
        end

        # Original version is `config.prepend_before(:each) do`
        # https://github.com/KnapsackPro/knapsack/blob/v1.17.0/lib/knapsack/adapters/rspec_adapter.rb#L9
        config.prepend_before(:each) do # rubocop:disable RSpec/HookArgument
          current_example_group =
            if ::RSpec.respond_to?(:current_example)
              ::RSpec.current_example.metadata[:example_group]
            else
              example.metadata
            end

          Knapsack.tracker.test_path = Knapsack::Adapters::RSpecAdapter.test_path(current_example_group)
        end

        # Original version stops timer in `config.append_after(:each) do`
        # https://github.com/KnapsackPro/knapsack/blob/v1.17.0/lib/knapsack/adapters/rspec_adapter.rb#L20
        config.append_after(:context) do
          Knapsack.tracker.stop_timer
        end

        config.after(:suite) do
          Knapsack.logger.info(Knapsack::Presenter.global_time)
        end
      end
    end
  end

  def self.configure!
    return unless ENV['CI'] && ENV['KNAPSACK_GENERATE_REPORT'] && !ENV['NO_KNAPSACK']

    RSpecContextAdapter.bind
  end
end
