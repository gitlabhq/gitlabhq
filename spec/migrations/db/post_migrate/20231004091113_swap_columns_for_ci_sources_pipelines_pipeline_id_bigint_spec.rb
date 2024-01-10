# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SwapColumnsForCiSourcesPipelinesPipelineIdBigint, feature_category: :continuous_integration do
  let(:connection) { active_record_base.connection }

  before do
    connection.execute('ALTER TABLE ci_sources_pipelines ALTER COLUMN pipeline_id TYPE integer')
    connection.execute('ALTER TABLE ci_sources_pipelines ALTER COLUMN pipeline_id_convert_to_bigint TYPE bigint')
  end

  it_behaves_like(
    'swap conversion columns',
    table_name: :ci_sources_pipelines,
    from: :pipeline_id,
    to: :pipeline_id_convert_to_bigint
  )

  context 'when indexes are missing' do
    before do
      connection.remove_index(
        :ci_sources_pipelines, name: :index_ci_sources_pipelines_on_pipeline_id, if_exists: true
      )
      connection.remove_index(
        :ci_sources_pipelines, name: :index_ci_sources_pipelines_on_source_pipeline_id, if_exists: true
      )
    end

    it_behaves_like(
      'swap conversion columns',
      table_name: :ci_sources_pipelines,
      from: :pipeline_id,
      to: :pipeline_id_convert_to_bigint
    )
  end
end
