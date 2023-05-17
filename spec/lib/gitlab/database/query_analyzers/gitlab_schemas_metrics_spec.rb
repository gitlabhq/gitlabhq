# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::GitlabSchemasMetrics, query_analyzers: false do
  let(:analyzer) { described_class }

  before do
    allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return([analyzer])
  end

  it 'does not increment metrics if feature flag is disabled' do
    stub_feature_flags(query_analyzer_gitlab_schema_metrics: false)

    expect(analyzer).not_to receive(:analyze)

    process_sql(ActiveRecord::Base, "SELECT 1 FROM projects")
  end

  context 'properly observes all queries', :add_ci_connection do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        "for simple query observes schema correctly" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects",
          expectations: {
            gitlab_schemas: "gitlab_main",
            db_config_name: "main"
          }
        },
        "for query accessing gitlab_ci and gitlab_main" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects LEFT JOIN ci_builds ON ci_builds.project_id=projects.id",
          expectations: {
            gitlab_schemas: "gitlab_ci,gitlab_main",
            db_config_name: "main"
          }
        },
        "for query accessing gitlab_ci and gitlab_main the gitlab_schemas is always ordered" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds LEFT JOIN projects ON ci_builds.project_id=projects.id",
          expectations: {
            gitlab_schemas: "gitlab_ci,gitlab_main",
            db_config_name: "main"
          }
        },
        "for query accessing CI database" => {
          model: Ci::ApplicationRecord,
          sql: "SELECT 1 FROM ci_builds",
          expectations: {
            gitlab_schemas: "gitlab_ci",
            db_config_name: "ci"
          }
        },
        "for query accessing gitlab_main and unknown schema" => {
          model: ApplicationRecord,
          sql: "SELECT 1 FROM projects LEFT JOIN not_in_schema ON not_in_schema.project_id=projects.id",
          expect_error:
             /Could not find gitlab schema for table not_in_schema/
        }
      }
    end

    with_them do
      around do |example|
        Gitlab::Database::QueryAnalyzer.instance.within { example.run }
      end

      it do
        allow(::Ci::ApplicationRecord.load_balancer).to receive(:configuration)
          .and_return(Gitlab::Database::LoadBalancing::Configuration.for_model(::Ci::ApplicationRecord))

        if expect_error
          expect { process_sql(model, sql) }.to raise_error(expect_error)
        else
          expect(described_class.schemas_metrics).to receive(:increment)
            .with(expectations).and_call_original

          process_sql(model, sql)
        end
      end
    end
  end

  def process_sql(model, sql)
    Gitlab::Database::QueryAnalyzer.instance.within do
      # Skip load balancer and retrieve connection assigned to model
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, model.retrieve_connection)
    end
  end
end
