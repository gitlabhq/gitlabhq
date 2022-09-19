# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/drop_table'

RSpec.describe RuboCop::Cop::Migration::DropTable do
  context 'when in deployment migration' do
    let(:msg) do
      '`drop_table` in deployment migrations requires downtime. Drop tables in post-deployment migrations instead.'
    end

    before do
      allow(cop).to receive(:in_deployment_migration?).and_return(true)
    end

    context 'with drop_table DSL method' do
      context 'when in down method' do
        it 'does not register an offense' do
          expect_no_offenses(<<~PATTERN)
            def down
              drop_table :table
            end
          PATTERN
        end
      end

      context 'when in up method' do
        it 'registers an offense' do
          expect_offense(<<~PATTERN)
            def up
              drop_table :table
              ^^^^^^^^^^  #{msg}
            end
          PATTERN
        end
      end

      context 'when in change method' do
        it 'registers an offense' do
          expect_offense(<<~PATTERN)
            def change
              drop_table :table
              ^^^^^^^^^^  #{msg}
            end
          PATTERN
        end
      end
    end

    context 'with DROP TABLE SQL literal' do
      it 'does not register an offense' do
        expect_no_offenses(<<~PATTERN)
          def down
            execute "DROP TABLE table"
          end
        PATTERN
      end
    end

    context 'when in up method' do
      it 'registers an offense' do
        expect_offense(<<~PATTERN)
          def up
            execute "DROP TABLE table"
            ^^^^^^^  #{msg}
          end
        PATTERN
      end
    end

    context 'when in change method' do
      it 'registers an offense' do
        expect_offense(<<~PATTERN)
          def change
            execute "DROP TABLE table"
            ^^^^^^^  #{msg}
          end
        PATTERN
      end
    end
  end

  context 'when in post-deployment migration' do
    before do
      allow(cop).to receive(:in_post_deployment_migration?).and_return(true)
    end

    it 'registers no offense' do
      expect_no_offenses(<<~PATTERN)
        def change
          drop_table :table
          execute "DROP TABLE table"
        end
      PATTERN
    end
  end

  context 'when outside of migration' do
    it 'registers no offense' do
      expect_no_offenses(<<~PATTERN)
        def change
          drop_table :table
          execute "DROP TABLE table"
        end
      PATTERN
    end
  end
end
