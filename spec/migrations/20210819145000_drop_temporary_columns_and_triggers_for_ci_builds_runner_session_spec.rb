# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropTemporaryColumnsAndTriggersForCiBuildsRunnerSession, :migration, feature_category: :runner do
  let(:ci_builds_runner_session_table) { table(:ci_builds_runner_session) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_builds_runner_session_table.column_names).to include('build_id_convert_to_bigint')
      }

      migration.after -> {
        ci_builds_runner_session_table.reset_column_information
        expect(ci_builds_runner_session_table.column_names).not_to include('build_id_convert_to_bigint')
      }
    end
  end
end
