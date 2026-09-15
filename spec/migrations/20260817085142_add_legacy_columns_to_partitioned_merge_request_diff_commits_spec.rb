# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddLegacyColumnsToPartitionedMergeRequestDiffCommits,
  feature_category: :code_review_workflow do
  let(:connection) { described_class.new.connection }
  let(:legacy_columns) do
    %w[sha message commit_author_id committer_id authored_date committed_date trailers]
  end

  # Type, nullability and default all have to match: the swap points existing queries at this
  # table, so any divergence here surfaces as a runtime error rather than a schema diff.
  def legacy_column_definitions(table)
    connection.columns(table)
              .select { |column| legacy_columns.include?(column.name) }
              .to_h { |column| [column.name, [column.sql_type, column.null, column.default]] }
  end

  it 'matches the merge_request_diff_commits definitions for the legacy columns' do
    expected = legacy_column_definitions(:merge_request_diff_commits)

    expect { migrate! }
      .to change { legacy_column_definitions(described_class::TABLE_NAME) }
            .from({})
            .to(expected)
  end

  it 'drops the columns again on rollback' do
    migrate!

    expect { schema_migrate_down! }
      .to change { legacy_column_definitions(described_class::TABLE_NAME) }
            .to({})
  end
end
