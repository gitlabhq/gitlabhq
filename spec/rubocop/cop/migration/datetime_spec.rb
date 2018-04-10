require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/datetime'

describe RuboCop::Cop::Migration::Datetime do
  include CopHelper

  subject(:cop) { described_class.new }

  let(:migration_with_datetime) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
          add_column(:users, :last_sign_in, :datetime)
        end
      end
    )
  end

  let(:migration_with_timestamp) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
          add_column(:users, :last_sign_in, :timestamp)
        end
      end
    )
  end

  let(:migration_without_datetime) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
        end
      end
    )
  end

  let(:migration_with_datetime_with_timezone) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
          add_column(:users, :last_sign_in, :datetime_with_timezone)
        end
      end
    )
  end

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when the ":datetime" data type is used' do
      inspect_source(migration_with_datetime)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([7])
        expect(cop.offenses.first.message).to include('datetime')
      end
    end

    it 'registers an offense when the ":timestamp" data type is used' do
      inspect_source(migration_with_timestamp)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([7])
        expect(cop.offenses.first.message).to include('timestamp')
      end
    end

    it 'does not register an offense when the ":datetime" data type is not used' do
      inspect_source(migration_without_datetime)

      aggregate_failures do
        expect(cop.offenses.size).to eq(0)
      end
    end

    it 'does not register an offense when the ":datetime_with_timezone" data type is used' do
      inspect_source(migration_with_datetime_with_timezone)

      aggregate_failures do
        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source(migration_with_datetime)
      inspect_source(migration_with_timestamp)
      inspect_source(migration_without_datetime)
      inspect_source(migration_with_datetime_with_timezone)

      expect(cop.offenses.size).to eq(0)
    end
  end
end
