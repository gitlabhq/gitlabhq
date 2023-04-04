# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapSentNotificationsIdColumns, feature_category: :database do
  describe '#up' do
    before do
      # A we call `schema_migrate_down!` before each example, and for this migration
      # `#down` is same as `#up`, we need to ensure we start from the expected state.
      connection = described_class.new.connection
      connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE integer')
      connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id_convert_to_bigint TYPE bigint')
      # rubocop: disable RSpec/AnyInstanceOf
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(run_migration?)
      # rubocop: enable RSpec/AnyInstanceOf
    end

    context 'when we are GitLab.com, dev, or test' do
      let(:run_migration?) { true }

      it 'swaps the integer and bigint columns' do
        sent_notifications = table(:sent_notifications)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              sent_notifications.reset_column_information

              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
              expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
            }

            migration.after -> {
              sent_notifications.reset_column_information

              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
              expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('integer')
            }
          end
        end
      end
    end

    context 'when we are NOT GitLab.com, dev, or test' do
      let(:run_migration?) { false }

      it 'does not swap the integer and bigint columns' do
        sent_notifications = table(:sent_notifications)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              sent_notifications.reset_column_information

              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
              expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
            }

            migration.after -> {
              sent_notifications.reset_column_information

              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
              expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }.sql_type).to eq('bigint')
            }
          end
        end
      end
    end
  end
end
