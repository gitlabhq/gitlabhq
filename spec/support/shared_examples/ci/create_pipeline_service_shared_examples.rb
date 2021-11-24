# frozen_string_literal: true

RSpec.shared_examples 'pipelines are created without N+1 SQL queries' do
  before do
    # warm up
    stub_ci_pipeline_yaml_file(config1)
    execute_service
  end

  it 'avoids N+1 queries', :aggregate_failures, :request_store, :use_sql_query_cache do
    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      stub_ci_pipeline_yaml_file(config1)

      pipeline = execute_service.payload

      expect(pipeline).to be_created_successfully
    end

    expect do
      stub_ci_pipeline_yaml_file(config2)

      pipeline = execute_service.payload

      expect(pipeline).to be_created_successfully
    end.not_to exceed_all_query_limit(control).with_threshold(accepted_n_plus_ones)
  end
end
