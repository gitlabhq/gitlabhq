# frozen_string_literal: true

require 'yaml'

module Support
  module RspecOrder
    TODO_YAML = File.join(__dir__, 'rspec_order_todo.yml')

    module_function

    def order_for(example_group)
      order_from_env || random_order(example_group)
    end

    def order_from_env
      return @order_from_env if defined?(@order_from_env)

      # Passing custom defined order via `--order NAME` is not supported.
      # For example, `--order reverse` does not work so we are passing it via
      # environment variable RSPEC_ORDER.
      @order_from_env = ENV['RSPEC_ORDER']
    end

    def random_order(example_group)
      path = example_group.metadata.fetch(:file_path)

      :random unless potential_order_dependent?(path)
    end

    def potential_order_dependent?(path)
      @todo ||= YAML.load_file(TODO_YAML).to_set # rubocop:disable Gitlab/PredicateMemoization

      @todo.include?(path)
    end

    # Adds '# order <ORDER>` below the example group description if the order
    # has been set to help debugging in case of failure.
    #
    # Previously, we've modified metadata[:description] directly but that led
    # to bugs. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96137
    module DocumentationFormatterPatch
      # See https://github.com/rspec/rspec-core/blob/v3.11.0/lib/rspec/core/formatters/documentation_formatter.rb#L24-L29
      def example_group_started(notification)
        super

        order = notification.group.metadata[:order]
        return unless order

        output.puts "#{current_indentation}# order #{order}"
      end
    end
  end
end

RSpec::Core::Formatters::DocumentationFormatter.prepend Support::RspecOrder::DocumentationFormatterPatch

RSpec.configure do |config|
  # Useful to find order-dependent specs.
  config.register_ordering(:reverse, &:reverse)

  # Randomization can be reproduced across test runs.
  Kernel.srand config.seed

  config.on_example_group_definition do |example_group|
    order = Support::RspecOrder.order_for(example_group)

    example_group.metadata[:order] = order.to_sym if order
  end
end
