# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::QueryRecorder, feature_category: :database, query_analyzers: false do
  # We keep only the QueryRecorder analyzer running
  around do |example|
    described_class.with_suppressed(false) do
      example.run
    end
  end

  context 'with query analyzer' do
    let(:log_path) { Rails.root.join(described_class::LOG_PATH) }
    let(:log_file) { described_class.log_file }

    after do
      ::Gitlab::Database::QueryAnalyzer.instance.end!([described_class])
    end

    shared_examples_for 'an enabled query recorder' do
      using RSpec::Parameterized::TableSyntax

      normalized_query = <<~SQL.strip.tr("\n", ' ')
        SELECT \\\\"projects\\\\".\\\\"id\\\\"
        FROM \\\\"projects\\\\"
        WHERE \\\\"projects\\\\".\\\\"namespace_id\\\\" = \\?
        AND \\\\"projects\\\\".\\\\"id\\\\" IN \\(\\?,\\?,\\?\\);
      SQL

      where(:list_parameter, :bind_parameters) do
        '$2, $3' | [1, 2, 3]
        '$2, $3, $4' | [1, 2, 3, 4]
        '$2 ,$3 ,$4 ,$5' | [1, 2, 3, 4, 5]
        '$2 , $3 , $4 , $5, $6' | [1, 2, 3, 4, 5, 6]
        '$2, $3 ,$4 , $5,$6,$7' | [1, 2, 3, 4, 5, 6, 7]
        '$2,$3,$4,$5,$6,$7,$8' | [1, 2, 3, 4, 5, 6, 7, 8]
      end

      with_them do
        before do
          allow(described_class).to receive(:analyze).and_call_original
          allow(FileUtils).to receive(:mkdir_p)
            .with(log_path)
        end

        it 'logs normalized queries to a file' do
          expect(File).to receive(:write)
            .with(log_file, /^{"normalized":"#{normalized_query}/, mode: 'a')

          expect do
            ApplicationRecord.connection.exec_query(<<~SQL.strip.tr("\n", ' '), 'SQL', bind_parameters)
              SELECT "projects"."id"
              FROM "projects"
              WHERE "projects"."namespace_id" = $1
              AND "projects"."id" IN (#{list_parameter});
            SQL
          end.not_to raise_error
        end
      end
    end

    context 'on default branch' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', nil)
        stub_env('CI_DEFAULT_BRANCH', 'default_branch_name')
        stub_env('CI_COMMIT_REF_NAME', 'default_branch_name')

        # This is needed to be able to stub_env the CI variable
        ::Gitlab::Database::QueryAnalyzer.instance.begin!([described_class])
      end

      it_behaves_like 'an enabled query recorder'
    end

    context 'on database merge requests' do
      before do
        stub_env('CI_MERGE_REQUEST_LABELS', 'database')

        # This is needed to be able to stub_env the CI variable
        ::Gitlab::Database::QueryAnalyzer.instance.begin!([described_class])
      end

      it_behaves_like 'an enabled query recorder'
    end
  end

  describe '.log_file' do
    let(:folder) { 'query_recorder' }
    let(:extension) { 'ndjson' }
    let(:default_name) { 'rspec' }
    let(:job_name) { 'test-job-1' }

    subject { described_class.log_file.to_s }

    context 'when in CI' do
      before do
        stub_env('CI_JOB_NAME_SLUG', job_name)
      end

      it { is_expected.to include("#{folder}/#{job_name}.#{extension}") }
      it { is_expected.not_to include("#{folder}/#{default_name}.#{extension}") }
    end

    context 'when not in CI' do
      before do
        stub_env('CI_JOB_NAME_SLUG', nil)
      end

      it { is_expected.to include("#{folder}/#{default_name}.#{extension}") }
      it { is_expected.not_to include("#{folder}/#{job_name}.#{extension}") }
    end
  end
end
