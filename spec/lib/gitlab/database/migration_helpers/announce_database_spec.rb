# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MigrationHelpers::AnnounceDatabase do
  let(:migration) do
    ActiveRecord::Migration.new('MyMigration', 1111).extend(described_class)
  end

  describe '#announce' do
    it 'prefixes message with database name' do
      expect { migration.announce('migrating') }.to output(/^main: == 1111 MyMigration: migrating/).to_stdout
    end
  end

  describe '#say' do
    it 'prefixes message with database name' do
      expect { migration.say('transaction_open?()') }.to output(/^main: -- transaction_open?()/).to_stdout
    end

    it 'prefixes subitem message with database name' do
      expect { migration.say('0.0000s', true) }.to output(/^main:    -> 0.0000s/).to_stdout
    end
  end

  describe '#write' do
    it 'does not prefix empty write' do
      expect { migration.write }.to output(/^$/).to_stdout
    end
  end
end
