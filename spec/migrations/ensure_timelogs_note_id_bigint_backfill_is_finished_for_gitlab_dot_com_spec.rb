# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnsureTimelogsNoteIdBigintBackfillIsFinishedForGitlabDotCom, feature_category: :database do
  describe '#up' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :expectation) do
      true  | true  | :to
      true  | false | :to
      false | true  | :to
      false | false | :not_to
    end

    with_them do
      it 'ensures the migration is completed for GitLab.com, dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)

        migration_arguments = {
          job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
          table_name: 'timelogs',
          column_name: 'id',
          job_arguments: [['note_id'], ['note_id_convert_to_bigint']]
        }

        expect(described_class).send(
          expectation,
          ensure_bacthed_background_migration_is_finished_for(migration_arguments)
        )

        migrate!
      end
    end
  end
end
