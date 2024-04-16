# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/change_column_null_on_high_traffic_table'

RSpec.describe RuboCop::Cop::Migration::ChangeColumnNullOnHighTrafficTable, feature_category: :database do
  let(:cop) { described_class.new }

  context 'when outside of a migration' do
    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        def up
          change_column_null :vulnerabilities, :name
        end
      RUBY
    end
  end

  context 'in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'when the helper is used without any argument' do
      it 'does not register any offenses' do
        expect_no_offenses(<<~RUBY)
          def up
            change_column_null
          end
        RUBY
      end
    end

    context 'when the helper is used with arguments' do
      context 'with discouraged helper on non high-traffic table' do
        it 'does not register any offenses' do
          expect_no_offenses(<<~RUBY)
            def up
              change_column_null :foo, :bar
            end
          RUBY
        end
      end

      context 'with discouraged helper on a high-traffic table' do
        let(:offense) do
          'Migration/ChangeColumnNullOnHighTrafficTable: ' \
            'Using `change_column_null` migration helper is risky for high-traffic tables. ' \
            'Please use `add_not_null_constraint` helper instead. ' \
            'For more details check https://docs.gitlab.com/ee/development/database/not_null_constraints.html#not-null-constraints-on-large-tables'
        end

        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def up
              change_column_null :vulnerabilities, :name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
            end
          RUBY
        end
      end
    end
  end
end
