require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/add_timestamps'

describe RuboCop::Cop::Migration::AddTimestamps do
  include CopHelper

  subject(:cop) { described_class.new }
  let(:migration_with_add_timestamps) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
          add_timestamps(:users)
        end
      end
    )
  end

  let(:migration_without_add_timestamps) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
        end
      end
    )
  end

  let(:migration_with_add_timestamps_with_timezone) do
    %q(
      class Users < ActiveRecord::Migration
        DOWNTIME = false

        def change
          add_column(:users, :username, :text)
          add_timestamps_with_timezone(:users)
        end
      end
    )
  end

  context 'in migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    it 'registers an offense when the "add_timestamps" method is used' do
      inspect_source(migration_with_add_timestamps)

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([7])
      end
    end

    it 'does not register an offense when the "add_timestamps" method is not used' do
      inspect_source(migration_without_add_timestamps)

      aggregate_failures do
        expect(cop.offenses.size).to eq(0)
      end
    end

    it 'does not register an offense when the "add_timestamps_with_timezone" method is used' do
      inspect_source(migration_with_add_timestamps_with_timezone)

      aggregate_failures do
        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context 'outside of migration' do
    it 'registers no offense' do
      inspect_source(migration_with_add_timestamps)
      inspect_source(migration_without_add_timestamps)
      inspect_source(migration_with_add_timestamps_with_timezone)

      expect(cop.offenses.size).to eq(0)
    end
  end
end
