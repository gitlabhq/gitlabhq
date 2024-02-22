# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rails/migration_timestamp'

RSpec.describe RuboCop::Cop::Rails::MigrationTimestamp, feature_category: :shared do
  context 'with timestamp in file name in the future' do
    it 'registers an offense' do
      expect_offense(<<~RUBY, '/db/migrate/30000220000000_some_migration.rb')
        print 1
        ^ The date of this file (`30000220000000_some_migration.rb`) must [...]
      RUBY
    end
  end

  context 'with an invalid date for the timestamp in file name in the future' do
    it 'registers an offense' do
      expect_offense(<<~RUBY, '/db/migrate/30002420000000_some_migration.rb')
        print 1
        ^ The date of this file (`30002420000000_some_migration.rb`) must [...]
      RUBY
    end
  end

  context 'with timestamp in file name in the past' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, '/db/migrate/19700101000000_some_migration.rb')
        print 1
      RUBY
    end
  end

  context 'without timestamp in the file name' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, '/db/migrate/some_migration.rb')
        print 1
      RUBY
    end
  end
end
