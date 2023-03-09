# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapTimelogsNoteIdToBigintForGitlabDotCom, feature_category: :database do
  describe '#up' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :swap) do
      true  | true  | true
      true  | false | true
      false | true  | true
      false | false | false
    end

    with_them do
      before do
        # A we call `schema_migrate_down!` before each example, and for this migration
        # `#down` is same as `#up`, we need to ensure we start from the expected state.
        connection = described_class.new.connection
        connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id TYPE integer')
        connection.execute('ALTER TABLE timelogs ALTER COLUMN note_id_convert_to_bigint TYPE bigint')
      end

      it 'swaps the integer and bigint columns for GitLab.com, dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)

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

              if swap
                expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('bigint')
                expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('integer')
              else
                expect(timelogs.columns.find { |c| c.name == 'note_id' }.sql_type).to eq('integer')
                expect(timelogs.columns.find { |c| c.name == 'note_id_convert_to_bigint' }.sql_type).to eq('bigint')
              end
            }
          end
        end
      end
    end
  end
end
