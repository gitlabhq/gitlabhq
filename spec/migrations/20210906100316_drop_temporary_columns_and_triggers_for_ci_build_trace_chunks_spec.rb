# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropTemporaryColumnsAndTriggersForCiBuildTraceChunks, feature_category: :continuous_integration do
  let(:ci_build_trace_chunks_table) { table(:ci_build_trace_chunks) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(ci_build_trace_chunks_table.column_names).to include('build_id_convert_to_bigint')
      }

      migration.after -> {
        ci_build_trace_chunks_table.reset_column_information
        expect(ci_build_trace_chunks_table.column_names).not_to include('build_id_convert_to_bigint')
      }
    end
  end
end
