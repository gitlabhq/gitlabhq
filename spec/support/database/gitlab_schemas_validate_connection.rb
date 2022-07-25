# frozen_string_literal: true

RSpec.configure do |config|
  def with_gitlab_schemas_validate_connection_prevented
    Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
      yield
    end
  end

  config.around(:each, :suppress_gitlab_schemas_validate_connection) do |example|
    with_gitlab_schemas_validate_connection_prevented(&example)
  end

  config.around(:each, query_analyzers: false) do |example|
    with_gitlab_schemas_validate_connection_prevented(&example)
  end
end
