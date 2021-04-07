# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/migration/add_timestamps'

RSpec.describe RuboCop::Cop::Migration::AddTimestamps do
  subject(:cop) { described_class.new }

  let(:migration_with_add_timestamps) do
    %q(
      class Users < ActiveRecord::Migration[4.2]
        def change
          add_column(:users, :username, :text)
          add_timestamps(:users)
        end
      end
    )
  end

  let(:migration_without_add_timestamps) do
    %q(
      class Users < ActiveRecord::Migration[4.2]
        def change
          add_column(:users, :username, :text)
        end
      end
    )
  end

  let(:migration_with_add_timestamps_with_timezone) do
    %q(
      class Users < ActiveRecord::Migration[4.2]
        def change
          add_column(:users, :username, :text)
          add_timestamps_with_timezone(:users)
        end
      end
    )
  end

  context 'when in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when the "add_timestamps" method is used' do
      expect_offense(<<~RUBY)
        class Users < ActiveRecord::Migration[4.2]
          def change
            add_column(:users, :username, :text)
            add_timestamps(:users)
            ^^^^^^^^^^^^^^ Do not use `add_timestamps`, use `add_timestamps_with_timezone` instead
          end
        end
      RUBY
    end

    it 'does not register an offense when the "add_timestamps" method is not used' do
      expect_no_offenses(migration_without_add_timestamps)
    end

    it 'does not register an offense when the "add_timestamps_with_timezone" method is used' do
      expect_no_offenses(migration_with_add_timestamps_with_timezone)
    end
  end

  context 'when outside of migration' do
    it 'registers no offense', :aggregate_failures do
      expect_no_offenses(migration_with_add_timestamps)
      expect_no_offenses(migration_without_add_timestamps)
      expect_no_offenses(migration_with_add_timestamps_with_timezone)
    end
  end
end
