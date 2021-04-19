# frozen_string_literal: true

require 'knapsack'

module KnapsackEnv
  def self.configure!
    return unless ENV['CI'] && ENV['KNAPSACK_GENERATE_REPORT'] && !ENV['NO_KNAPSACK']

    Knapsack::Adapters::RSpecAdapter.bind
  end
end
