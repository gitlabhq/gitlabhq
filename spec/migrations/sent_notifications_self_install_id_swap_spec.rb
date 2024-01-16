# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SentNotificationsSelfInstallIdSwap, feature_category: :database do
  let(:connection) { described_class.new.connection }

  describe '#up' do
    before do
      # rubocop: disable RSpec/AnyInstanceOf -- This mixin is only used for migrations, it's okay to use this
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(dot_com?)
      # rubocop: enable RSpec/AnyInstanceOf
    end

    context 'when we are NOT GitLab.com, dev, or test' do
      let(:dot_com?) { false }

      context 'when sent_notifications.id is not a bigint' do
        around do |example|
          connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE integer')
          example.run
          connection.execute('ALTER TABLE sent_notifications ALTER COLUMN id TYPE bigint')
        end

        context 'when id_convert_to_bigint exists' do
          around do |example|
            connection.execute('ALTER TABLE sent_notifications ADD COLUMN IF NOT EXISTS id_convert_to_bigint bigint')
            Gitlab::Database::UnidirectionalCopyTrigger.on_table(:sent_notifications, connection: connection).create(
              :id, :id_convert_to_bigint)
            example.run
            connection.execute('ALTER TABLE sent_notifications DROP COLUMN id_convert_to_bigint')
          end

          it 'swaps the integer and bigint columns' do
            sent_notifications = table(:sent_notifications)
            disable_migrations_output do
              reversible_migration do |migration|
                migration.before -> {
                  sent_notifications.reset_column_information
                  expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('integer')
                  expect(sent_notifications.columns.find do |c|
                           c.name == 'id_convert_to_bigint'
                         end.sql_type).to eq('bigint')
                }

                migration.after -> {
                  sent_notifications.reset_column_information
                  expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
                  expect(sent_notifications.columns.find do |c|
                           c.name == 'id_convert_to_bigint'
                         end.sql_type).to eq('integer')
                }
              end
            end
          end
        end
      end
    end

    context 'when any other condition' do
      let(:dot_com?) { true }

      it 'does not do anything' do
        sent_notifications = table(:sent_notifications)

        disable_migrations_output do
          reversible_migration do |migration|
            migration.before -> {
              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            }

            migration.after -> {
              expect(sent_notifications.columns.find { |c| c.name == 'id' }.sql_type).to eq('bigint')
            }
          end
        end
      end
    end
  end
end
