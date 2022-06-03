# frozen_string_literal: true

RSpec.shared_examples 'avoids N+1 queries on environment detail page' do
  it 'avoids N+1 queries', :use_sql_query_cache do
    create_deployment_with_associations(commit_depth: 19)

    control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
      get project_environment_path(project, environment), params: environment_params
    end

    18.downto(0).each { |n| create_deployment_with_associations(commit_depth: n) }

    # N+1s exist for loading commit emails and users
    expect do
      get project_environment_path(project, environment), params: environment_params
    end.not_to exceed_all_query_limit(control).with_threshold(9)
  end
end
