# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapDesignUserMentionsNoteIdToBigintForGitlabDotCom, feature_category: :database do
  describe '#up' do
    before do
      # A we call `schema_migrate_down!` before each example, and for this migration
      # `#down` is same as `#up`, we need to ensure we start from the expected state.
      connection = described_class.new.connection
      connection.execute('ALTER TABLE design_user_mentions ALTER COLUMN note_id TYPE integer')
      connection.execute('ALTER TABLE design_user_mentions ALTER COLUMN note_id_convert_to_bigint TYPE bigint')
    end

    # rubocop: disable RSpec/AnyInstanceOf
    it 'swaps the integer and bigint columns for GitLab.com, dev, or test' do
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(true)

      user_mentions = table(:design_user_mentions)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            user_mentions.reset_column_information

            expect(user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
            expect(user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
          }

          migration.after -> {
            user_mentions.reset_column_information

            expect(user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
            expect(user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('integer')
          }
        end
      end
    end

    it 'is a no-op for other instances' do
      allow_any_instance_of(described_class).to receive(:com_or_dev_or_test_but_not_jh?).and_return(false)

      user_mentions = table(:design_user_mentions)

      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            user_mentions.reset_column_information

            expect(user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
            expect(user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
          }

          migration.after -> {
            user_mentions.reset_column_information

            expect(user_mentions.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
            expect(user_mentions.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
          }
        end
      end
    end
    # rubocop: enable RSpec/AnyInstanceOf
  end
end
