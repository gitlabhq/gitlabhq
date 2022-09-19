# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/timestamps'

RSpec.describe RuboCop::Cop::Migration::Timestamps do
  let(:migration_with_timestamps) do
    %q(
      class Users < ActiveRecord::Migration[4.2]
        def change
          create_table :users do |t|
            t.string :username, null: false
            t.timestamps null: true
            t.string :password
          end
        end
      end
    )
  end

  let(:migration_without_timestamps) do
    %q(
      class Users < ActiveRecord::Migration[4.2]
        def change
          create_table :users do |t|
            t.string :username, null: false
            t.string :password
          end
        end
      end
    )
  end

  let(:migration_with_timestamps_with_timezone) do
    %q(
      class Users < ActiveRecord::Migration[4.2]
        def change
          create_table :users do |t|
            t.string :username, null: false
            t.timestamps_with_timezone null: true
            t.string :password
          end
        end
      end
    )
  end

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when the "timestamps" method is used' do
      expect_offense(<<~RUBY)
        class Users < ActiveRecord::Migration[4.2]
          def change
            create_table :users do |t|
              t.string :username, null: false
              t.timestamps null: true
                ^^^^^^^^^^ Do not use `timestamps`, use `timestamps_with_timezone` instead
              t.string :password
            end
          end
        end
      RUBY
    end

    it 'does not register an offense when the "timestamps" method is not used' do
      expect_no_offenses(migration_without_timestamps)
    end

    it 'does not register an offense when the "timestamps_with_timezone" method is used' do
      expect_no_offenses(migration_with_timestamps_with_timezone)
    end
  end

  context 'outside of migration' do
    it 'registers no offense', :aggregate_failures do
      expect_no_offenses(migration_with_timestamps)
      expect_no_offenses(migration_without_timestamps)
      expect_no_offenses(migration_with_timestamps_with_timezone)
    end
  end
end
