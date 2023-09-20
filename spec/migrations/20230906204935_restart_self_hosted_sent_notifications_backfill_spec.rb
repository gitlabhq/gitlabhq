# frozen_string_literal: true

require 'spec_helper'

require_migration!

def column_type_from_table(table, column)
  table.columns.find { |c| c.name == column }.sql_type
end

def sent_notifications_backfills(connection)
  res = connection.execute <<~SQL
    SELECT * FROM batched_background_migrations WHERE table_name = 'sent_notifications'
  SQL

  res.ntuples
end

def create_previous_backfill(connection)
  connection.execute <<~SQL
    INSERT INTO batched_background_migrations
      (min_value, max_value, batch_size, sub_batch_size, interval, "status",#{' '}
      job_class_name, batch_class_name,
      table_name, column_name, job_arguments,
      gitlab_schema, created_at, updated_at)
    VALUES
      (1, 3, 20000, 1000, 120, 3,
      'CopyColumnUsingBackgroundMigrationJob', 'PrimaryKeyBatchingStrategy',
      'sent_notifications', 'id', '[["id"], ["id_convert_to_bigint"]]',
      'gitlab_main', NOW(), NOW())
  SQL
end

RSpec.describe RestartSelfHostedSentNotificationsBackfill, feature_category: :database do
  let(:sent_notifications) { table(:sent_notifications) }

  before do
    # rubocop: disable RSpec/AnyInstanceOf
    allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(!self_hosted)
    # rubocop: enable RSpec/AnyInstanceOf
  end

  describe '#up' do
    context 'when is self-hosted' do
      let(:self_hosted) { true }

      context 'when id is integer' do
        before do
          described_class.new.connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE integer')
          described_class.new.connection.execute(
            'ALTER TABLE sent_notifications ADD COLUMN IF NOT EXISTS id_convert_to_bigint BIGINT'
          )
          sent_notifications.reset_column_information
        end

        after do
          described_class.new.connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
          described_class.new.connection.execute(
            'ALTER TABLE sent_notifications DROP COLUMN IF EXISTS id_convert_to_bigint'
          )
          sent_notifications.reset_column_information
        end

        context 'when a backfill has never been done' do
          let(:id_convert_to_bigint_sample) { 0 }

          before do
            described_class.new.connection.execute <<~SQL
                INSERT INTO
                    sent_notifications
                (id_convert_to_bigint, reply_key)
                VALUES (#{id_convert_to_bigint_sample}, 4)
            SQL
          end

          after do
            described_class.new.connection.execute <<~SQL
                DELETE FROM sent_notifications
            SQL
          end

          context 'when there is a record of an incomplete backfill' do
            before do
              create_previous_backfill(described_class.new.connection)
            end

            after do
              described_class.new.connection.execute <<~SQL
                  DELETE FROM batched_background_migrations
              SQL
            end

            it 'calls delete_batched_background_migration and does not raise an error' do
              expect_next_instance_of(described_class) do |instance|
                expect(instance).to receive(:delete_batched_background_migration)
              end
              disable_migrations_output do
                expect { migrate! }.not_to raise_error
              end
              expect(sent_notifications_backfills(described_class.new.connection)).to eq 1
            end
          end

          context 'when there is no previous record of a backfill' do
            it 'begins a backfill' do
              disable_migrations_output do
                migrate!
              end
              expect(sent_notifications_backfills(described_class.new.connection)).to eq 1
            end
          end
        end

        context 'when a backfill has previously been done' do
          let(:id_convert_to_bigint_sample) { 4 }

          before do
            described_class.new.connection.execute <<~SQL
                INSERT INTO
                    sent_notifications
                (id_convert_to_bigint, reply_key)
                VALUES (#{id_convert_to_bigint_sample}, 4)
            SQL
          end

          after do
            described_class.new.connection.execute <<~SQL
                DELETE FROM sent_notifications
            SQL
          end

          it 'does not start a backfill' do
            disable_migrations_output do
              migrate!
            end
            expect(sent_notifications_backfills(described_class.new.connection)).to eq 0
          end
        end
      end

      context 'when id is a bigint' do
        it 'does not start a backfill' do
          disable_migrations_output do
            migrate!
          end
          expect(sent_notifications_backfills(described_class.new.connection)).to eq 0
        end
      end
    end

    context 'when is not self-hosted' do
      let(:self_hosted) { false }

      it 'does not start a backfill' do
        disable_migrations_output do
          migrate!
        end
        expect(sent_notifications_backfills(described_class.new.connection)).to eq 0
      end
    end
  end
end
