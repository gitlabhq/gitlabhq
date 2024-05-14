# frozen_string_literal: true

require 'rubocop_spec_helper'

require 'rspec-parameterized'
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

  context 'when file name format is bad' do
    where(:filename) do
      %w[
        some_migration.rb
        123456789_some_migration.rb
        19700101000000_some_2fa_migration.rb.rb
        19700101000000_some_2fa_migration..rb
        19700101000000.rb
        19700101000000_.rb
        19700101000000_a.rb
        19700101000000_a_.rb
        19700101000000_1.rb
        19700101000000_1_.rb
      ]
    end

    with_them do
      it 'registers an offense' do
        expect_offense(<<~RUBY, "/db/migrate/#{filename}")
          print 1
          ^ The filename format of (`#{filename}`) must [...]
        RUBY
      end
    end
  end

  context 'when file name is good' do
    where(:filename) do
      %w[
        19700101000000_some_2fa_migration.rb
        19700101000000_some_migration.rb
        19700101000000_a_b.rb
        19700101000000_1_2.rb
      ]
    end

    with_them do
      it 'registers an offense' do
        expect_no_offenses(<<~RUBY, "/db/migrate/#{filename}")
          print 1
        RUBY
      end
    end
  end
end
