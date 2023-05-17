# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeCiBuildNeedsBigIntConversion, migration: :gitlab_ci, feature_category: :continuous_integration do
  describe '#up' do
    using RSpec::Parameterized::TableSyntax

    where(:dot_com, :dev_or_test, :jh, :expectation) do
      true  | true  | true  | :not_to
      true  | false | true  | :not_to
      false | true  | true  | :not_to
      false | false | true  | :not_to
      true  | true  | false | :to
      true  | false | false | :to
      false | true  | false | :to
      false | false | false | :not_to
    end

    with_them do
      it 'ensures the migration is completed for GitLab.com, dev, or test' do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test)
        allow(Gitlab).to receive(:jh?).and_return(jh)

        migration_arguments = {
          job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
          table_name: 'ci_build_needs',
          column_name: 'id',
          job_arguments: [['id'], ['id_convert_to_bigint']]
        }

        expect(described_class).send(
          expectation,
          ensure_batched_background_migration_is_finished_for(migration_arguments)
        )

        migrate!
      end
    end
  end
end
