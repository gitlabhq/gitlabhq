# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapTimelogsNoteIdToBigintForGitlabDotCom, feature_category: :database do
  describe '#up' do
    before do
      # A we call `schema_migrate_down!` before each example, and for this migration
      # `#down` is same as `#up`, we need to ensure we start from the expected state.
      connection = described_class.new.connection
      connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id TYPE integer')
      connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id_convert_to_bigint TYPE bigint')
    end

    # rubocop: disable RSpec/AnyInstanceOf
    it 'swaps the integer and bigint columns for GitLab.com, dev, or test' do
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)

      timelogs = table(:timelogs)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            timelogs.reset_column_information

            expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
            expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
          }

          migration.after -> {
            timelogs.reset_column_information

            expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
            expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('integer')
          }
        end
      end
    end

    it 'is a no-op for other instances' do
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)

      timelogs = table(:timelogs)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            timelogs.reset_column_information

            expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
            expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
          }

          migration.after -> {
            timelogs.reset_column_information

            expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
            expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
          }
        end
      end
    end
    # rubocop: enable RSpec/AnyInstanceOf
  end
end
