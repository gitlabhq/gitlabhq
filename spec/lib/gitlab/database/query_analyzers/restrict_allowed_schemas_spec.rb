# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas,
  query_analyzers: false, feature_category: :database do
  let(:analyzer) { described_class }

  context 'properly analyzes queries' do
    using RSpec::Parameterized::TableSyntax

    where do
      examples = {
        "for SELECT on projects" => {
          sql: "SELECT 1 FROM projects",
          expected_allowed_gitlab_schemas: {
            no_schema: :dml_not_allowed,
            gitlab_main: :success,
            gitlab_main_clusterwide: :success,
            gitlab_main_cell: :success,
            gitlab_ci: :dml_access_denied # cross-schema access
          }
        },
        "for SELECT on namespaces" => {
          sql: "SELECT 1 FROM namespaces",
          expected_allowed_gitlab_schemas: {
            no_schema: :dml_not_allowed,
            gitlab_main: :success,
            gitlab_main_clusterwide: :success,
            gitlab_main_cell: :success,
            gitlab_ci: :dml_access_denied # cross-schema access
          }
        },
        "for INSERT on projects" => {
          sql: "INSERT INTO projects VALUES (1)",
          expected_allowed_gitlab_schemas: {
            no_schema: :dml_not_allowed,
            gitlab_main: :success,
            gitlab_main_clusterwide: :success,
            gitlab_main_cell: :success,
            gitlab_ci: :dml_access_denied # cross-schema access
          }
        },
        "for INSERT on namespaces" => {
          sql: "INSERT INTO namespaces VALUES (1)",
          expected_allowed_gitlab_schemas: {
            no_schema: :dml_not_allowed,
            gitlab_main: :success,
            gitlab_main_clusterwide: :success,
            gitlab_main_cell: :success,
            gitlab_ci: :dml_access_denied # cross-schema access
          }
        },
        "for CREATE INDEX" => {
          sql: "CREATE INDEX index_projects_on_hidden ON projects (hidden)",
          expected_allowed_gitlab_schemas: {
            no_schema: :success,
            gitlab_main: :ddl_not_allowed,
            gitlab_ci: :ddl_not_allowed
          }
        },
        "for CREATE SCHEMA" => {
          sql: "CREATE SCHEMA __test_schema",
          expected_allowed_gitlab_schemas: {
            no_schema: :success,
            # TODO: This is currently not properly detected
            gitlab_main: :success,
            gitlab_ci: :success
          }
        },
        "for CREATE FUNCTION" => {
          sql: "CREATE FUNCTION add(integer, integer) RETURNS integer AS 'select $1 + $2;' LANGUAGE SQL",
          expected_allowed_gitlab_schemas: {
            no_schema: :success,
            gitlab_main: :ddl_not_allowed,
            gitlab_ci: :ddl_not_allowed
          }
        },
        "for CREATE TRIGGER" => {
          sql: "CREATE TRIGGER check_projects BEFORE UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE check_projects_update()",
          expected_allowed_gitlab_schemas: {
            no_schema: :success,
            gitlab_main: :ddl_not_allowed,
            gitlab_ci: :ddl_not_allowed
          }
        },
        "for CREATE VIEW" => {
          sql: "CREATE VIEW my_view AS SELECT * FROM issues",
          expected_allowed_gitlab_schemas: {
            no_schema: :success,
            gitlab_main: :ddl_not_allowed,
            gitlab_ci: :ddl_not_allowed
          }
        }
      }

      # Expands all examples into individual tests
      examples.flat_map do |name, configuration|
        configuration[:expected_allowed_gitlab_schemas].map do |allowed_gitlab_schema, expectation|
          [
            "#{name} for allowed_gitlab_schema=#{allowed_gitlab_schema}",
            {
              sql: configuration[:sql],
              allowed_gitlab_schema: allowed_gitlab_schema, # nil, gitlab_main
              expectation: expectation # success, dml_access_denied, ...
            }
          ]
        end
      end.to_h
    end

    with_them do
      subject do
        process_sql(sql) do
          analyzer.allowed_gitlab_schemas = [allowed_gitlab_schema] unless allowed_gitlab_schema == :no_schema
        end
      end

      it do
        case expectation
        when :success
          expect { subject }.not_to raise_error
        when :ddl_not_allowed
          expect { subject }.to raise_error(described_class::DDLNotAllowedError)
        when :dml_not_allowed
          expect { subject }.to raise_error(described_class::DMLNotAllowedError)
        when :dml_access_denied
          expect { subject }.to raise_error(described_class::DMLAccessDeniedError)
        else
          raise "invalid expectation: #{expectation}"
        end
      end
    end
  end

  describe '.require_ddl_mode!' do
    subject { described_class.require_ddl_mode! }

    it "when not configured does not raise exception" do
      expect { subject }.not_to raise_error
    end

    it "when no schemas are configured does not raise exception (DDL mode)" do
      with_analyzer do
        expect { subject }.not_to raise_error
      end
    end

    it "with schemas configured does raise exception (DML mode)" do
      with_analyzer do
        analyzer.allowed_gitlab_schemas = %i[gitlab_main]

        expect { subject }.to raise_error(described_class::DMLNotAllowedError)
      end
    end
  end

  describe '.require_dml_mode!' do
    subject { described_class.require_dml_mode! }

    it "when not configured does not raise exception" do
      expect { subject }.not_to raise_error
    end

    it "when no schemas are configured does raise exception (DDL mode)" do
      with_analyzer do
        expect { subject }.to raise_error(described_class::DDLNotAllowedError)
      end
    end

    it "with schemas configured does raise exception (DML mode)" do
      with_analyzer do
        analyzer.allowed_gitlab_schemas = %i[gitlab_main]

        expect { subject }.not_to raise_error
      end
    end
  end

  def with_analyzer
    Gitlab::Database::QueryAnalyzer.instance.within([analyzer]) do
      yield
    end
  end

  def process_sql(sql, model = ActiveRecord::Base)
    with_analyzer do
      yield if block_given?

      # Skip load balancer and retrieve connection assigned to model
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, model.retrieve_connection, 'load')
    end
  end
end
