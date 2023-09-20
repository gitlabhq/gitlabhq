# frozen_string_literal: true

require 'spec_helper'

require_migration!

def column_type_from_table(table, column)
  table.columns.find { |c| c.name == column }.sql_type
end

RSpec.describe RestartSelfHostedSentNotificationsBigintConversion, feature_category: :database do
  let(:sent_notifications) { table(:sent_notifications) }

  before do
    # rubocop: disable RSpec/AnyInstanceOf
    allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(!self_hosted)
    # rubocop: enable RSpec/AnyInstanceOf
  end

  context 'when is self-hosted' do
    let(:self_hosted) { true }

    describe '#up' do
      context 'when id is already a bigint' do
        it 'does nothing' do
          disable_migrations_output do
            reversible_migration do |migration|
              migration.before -> {
                sent_notifications.reset_column_information
                expect(column_type_from_table(sent_notifications, 'id')).to eq('bigint')
              }
              migration.after -> {
                sent_notifications.reset_column_information
                expect(column_type_from_table(sent_notifications, 'id')).to eq('bigint')
              }
            end
          end
        end
      end

      context 'when id is an integer and id_convert_to_bigint exists' do
        before do
          conn = described_class.new.connection
          conn.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE integer')
          conn.execute('ALTER TABLE sent_notifications ADD COLUMN id_convert_to_bigint BIGINT')
          sent_notifications.reset_column_information
        end

        after do
          conn = described_class.new.connection
          conn.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
          conn.execute('ALTER TABLE sent_notifications DROP COLUMN id_convert_to_bigint')
          sent_notifications.reset_column_information
        end

        it 'does nothing' do
          disable_migrations_output do
            expect(column_type_from_table(sent_notifications, 'id')).to eq('integer')
            expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).not_to be_nil
            migrate!
            expect(column_type_from_table(sent_notifications, 'id')).to eq('integer')
            expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).not_to be_nil
          end
        end
      end

      context 'when id is an integer and id_convert_to_bigint does not exist' do
        before do
          conn = described_class.new.connection
          conn.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE integer')
          conn.execute('ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint')
          sent_notifications.reset_column_information
        end

        after do
          conn = described_class.new.connection
          conn.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
          conn.execute('ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint')
          sent_notifications.reset_column_information
        end

        it 'creates id_convert_to_bigint' do
          disable_migrations_output do
            expect(column_type_from_table(sent_notifications, 'id')).to eq('integer')
            expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be_nil
            migrate!
            sent_notifications.reset_column_information
            expect(column_type_from_table(sent_notifications, 'id')).to eq('integer')
            expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).not_to be_nil
          end
        end
      end
    end

    describe '#down' do
      context 'when id is an integer and id_convert_to_bigint exists' do
        before do
          conn = described_class.new.connection
          conn.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE integer')
          conn.execute('ALTER TABLE sent_notifications ADD COLUMN id_convert_to_bigint BIGINT')
          sent_notifications.reset_column_information
        end

        after do
          conn = described_class.new.connection
          conn.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
          conn.execute('ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint')
          sent_notifications.reset_column_information
        end

        it 'drops id_convert_to_bigint' do
          disable_migrations_output do
            migrate!
            schema_migrate_down!
          end
          expect(sent_notifications.columns.find { |c| c.name == 'id_convert_to_bigint' }).to be_nil
        end
      end
    end
  end

  context 'when is not self-hosted' do
    let(:self_hosted) { false }

    describe '#up' do
      it 'is a bigint and result in no change' do
        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              sent_notifications.reset_column_information
              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            }
            migration.after -> {
              sent_notifications.reset_column_information
              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            }
          end
        end
      end
    end

    # Do not need to describe #down since it's a no-op and we did reversible test above
  end
end
