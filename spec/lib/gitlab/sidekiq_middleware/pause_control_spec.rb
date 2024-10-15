# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl, feature_category: :global_search do
  describe '.for' do
    using RSpec::Parameterized::TableSyntax

    where(:strategy_name, :expected_class) do
      :none                  | ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::None
      :unknown               | ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::None
      :click_house_migration | ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::ClickHouseMigration
      :zoekt                 | ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::Zoekt
      :deprecated            | ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::Deprecated
    end

    with_them do
      it 'returns the right class' do
        expect(described_class.for(strategy_name)).to eq(expected_class)
      end
    end
  end
end
