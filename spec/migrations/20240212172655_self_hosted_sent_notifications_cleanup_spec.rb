# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SelfHostedSentNotificationsCleanup, feature_category: :database do
  after do
    connection = described_class.new.connection
    connection.execute('ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint')
  end

  describe '#up' do
    context 'when is GitLab.com, dev, or test' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does nothing' do
        # rubocop: disable RSpec/AnyInstanceOf -- This is the easiest way to test this method
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)
        # rubocop: enable RSpec/AnyInstanceOf

        sent_notifications = table(:sent_notifications)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              sent_notifications.reset_column_information

              expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }

            migration.after -> {
              sent_notifications.reset_column_information

              expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
            }
          end
        end
      end
    end

    context 'when is a self-host customer with the temporary column already dropped' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint')
      end

      it 'does nothing' do
        # rubocop: disable RSpec/AnyInstanceOf  -- This is the easiest way to test this method
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        sent_notifications = table(:sent_notifications)
        disable_migrations_output do
          migrate!
        end

        expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
        expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
      end
    end

    context 'when is a self-host with the temporary columns' do
      before do
        connection = described_class.new.connection
        connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
        connection.execute('ALTER TABLE sent_notifications ADD COLUMN IF NOT EXISTS id_convert_to_bigint integer')
      end

      it 'drops the temporary columns' do
        # rubocop: disable RSpec/AnyInstanceOf  -- This is the easiest way to test this method
        allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)
        # rubocop: enable RSpec/AnyInstanceOf

        sent_notifications = table(:sent_notifications)

        disable_migrations_output do
          sent_notifications.reset_column_information

          expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
          expect(sent_notifications.columns.find do |c|
                   c.name == 'id_convert_to_bigint'
                 end.sql_type).to eq('integer')
          migrate!
          sent_notifications.reset_column_information

          expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
          expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be nil
        end
      end
    end
  end
end
