# frozen_string_literal: true

# rubocop:disable Gitlab/Json -- no Rails environment

require "tempfile"
require "fileutils"
require "fast_spec_helper"

require_relative "../../../../../tooling/lib/tooling/predictive_tests/metrics_exporter"

RSpec.describe Tooling::PredictiveTests::MetricsExporter, feature_category: :tooling do
  include StubENV

  subject(:exporter) do
    described_class.new(
      test_type: test_type,
      all_failed_tests_file: failed_tests_file,
      test_runtime_report_file: knapsack_report_file,
      output_dir: output_dir,
      log_level: :fatal
    )
  end

  let(:clickhouse_client) { instance_double(GitlabQuality::TestTooling::ClickHouse::Client, insert_json_data: nil) }

  let(:mapping_fetcher) do
    instance_double(
      Tooling::PredictiveTests::MappingFetcher,
      fetch_frontend_fixtures_mappings: nil,
      fetch_rspec_mappings: nil
    )
  end

  let(:find_changes) do
    instance_double(Tooling::FindChanges, execute: ["base_changes"])
  end

  let(:test_selector_described) do
    instance_double(Tooling::PredictiveTests::TestSelector, rspec_spec_list: [mappings.dig(:user, :spec)])
  end

  let(:test_selector_coverage) do
    instance_double(Tooling::PredictiveTests::TestSelector, rspec_spec_list: mappings.values.pluck(:spec))
  end

  let(:test_type) { :backend }
  let(:ci_env) do
    {
      job_id: "123",
      pipeline_id: "321",
      project_id: "456",
      project_path: "gitlab-org/gitlab",
      merge_request_iid: "789"
    }
  end

  # temporary folder for inputs and outputs
  let(:input_dir) { Dir.mktmpdir("predictive-tests-input") }
  let(:output_dir) { Dir.mktmpdir("predictive-tests-output") }
  # various input files used by MetricsExporter to create metrics output
  let(:failed_tests_file) { File.join(input_dir, "failed_test.txt") }
  let(:knapsack_report_file) { File.join(input_dir, "knapsack_report.json") }

  let(:temp_files) do
    {
      coverage_mapping: File.join(Dir.tmpdir, "coverage_mapping.json"),
      described_class_mapping: File.join(Dir.tmpdir, "described_class_mapping.json"),
      frontend_fixtures: File.join(Dir.tmpdir, "frontend_fixtures_mapping.json"),
      jest_matching_tests: File.join(Dir.tmpdir, "predictive_jest_matching_tests.txt")
    }
  end

  let(:mappings) do
    {
      user: { model: "app/models/user.rb", spec: "spec/models/user_spec.rb" },
      todo: { model: "app/models/todo.rb", spec: "spec/models/todo_spec.rb" },
      project: { model: "app/models/project.rb", spec: "spec/models/project_spec.rb" }
    }
  end

  let(:knapsack_report_json) do
    {
      mappings.dig(:user, :spec) => 2,
      mappings.dig(:todo, :spec) => 1
    }
  end

  let(:changed_files) { mappings.values.pluck(:model) + changed_js_files }
  let(:changed_js_files) { ["some_changed_file.js"] }
  let(:jest_matching_tests) { ["spec/frontend/project_spec.js", "spec/frontend/todo_spec.js"] }
  let(:failed_tests_content) { "" }

  let(:described_class_mapping_content) do
    { mappings.dig(:user, :model) => [mappings.dig(:user, :spec)] }.to_json
  end

  let(:coverage_mapping_content) do
    mappings.values.to_h { |mapping| [mapping[:model], [mapping[:spec]]] }.to_json
  end

  def read_metrics(strategy)
    JSON.parse(File.read(File.join(output_dir, test_type.to_s, "metrics_#{strategy}.json"))).except("timestamp")
  end

  def expect_clickhouse_row(
    strategy, changed_files_count:,
    predicted_test_files_count:,
    missed_failing_test_files:,
    predicted_failing_test_files:,
    failed_test_files_count:,
    projected_test_runtime_seconds: 0,
    test_files_missing_runtime_count: 0
  )
    expect(clickhouse_client).to have_received(:insert_json_data).with(
      "predictive_tests",
      [hash_including(
        test_type: test_type.to_s,
        strategy: strategy,
        ci_job_id: ci_env[:job_id].to_i,
        ci_pipeline_id: ci_env[:pipeline_id].to_i,
        ci_project_id: ci_env[:project_id].to_i,
        ci_project_path: ci_env[:project_path],
        ci_merge_request_iid: ci_env[:merge_request_iid].to_i,
        changed_files_count: changed_files_count,
        predicted_test_files_count: predicted_test_files_count,
        missed_failing_test_files: missed_failing_test_files,
        predicted_failing_test_files: predicted_failing_test_files,
        failed_test_files_count: failed_test_files_count,
        projected_test_runtime_seconds: projected_test_runtime_seconds,
        test_files_missing_runtime_count: test_files_missing_runtime_count
      )]
    )
  end

  before do
    stub_env({
      "CI_JOB_ID" => ci_env[:job_id],
      "CI_PIPELINE_ID" => ci_env[:pipeline_id],
      "GLCI_DA_CLICKHOUSE_URL" => "https://clickhouse.example.com",
      "GLCI_CLICKHOUSE_METRICS_USERNAME" => "user",
      "GLCI_CLICKHOUSE_METRICS_PASSWORD" => "pass",
      "GLCI_CLICKHOUSE_METRICS_DB" => "test_db",
      "GLCI_PREDICTIVE_TESTS_CLICKHOUSE_TABLE" => "predictive_tests",
      "CI_PROJECT_ID" => ci_env[:project_id],
      "CI_PROJECT_PATH" => ci_env[:project_path],
      "CI_MERGE_REQUEST_IID" => ci_env[:merge_request_iid]
    })

    # create folders and files used as input
    {
      temp_files[:coverage_mapping] => coverage_mapping_content,
      temp_files[:described_class_mapping] => described_class_mapping_content,
      failed_tests_file => failed_tests_content,
      knapsack_report_file => knapsack_report_json.to_json
    }.each do |file, content|
      next if file.nil?

      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, content)
    end

    allow(Tooling::FindChanges).to receive(:new).with(
      from: :api,
      frontend_fixtures_mapping_pathname: temp_files[:frontend_fixtures]
    ).and_return(find_changes)
    allow(GitlabQuality::TestTooling::ClickHouse::Client).to receive(:new).with(
      url: "https://clickhouse.example.com",
      database: "test_db",
      username: "user",
      password: "pass",
      logger: kind_of(Logger)
    ).and_return(clickhouse_client)
    allow(Tooling::PredictiveTests::MappingFetcher).to receive(:new).with(
      logger: kind_of(Logger)
    ).and_return(mapping_fetcher)
    allow(Tooling::PredictiveTests::ChangedFiles).to receive(:fetch).with(
      changes: ["base_changes"]
    ).and_return(changed_files)

    allow(Tooling::PredictiveTests::TestSelector).to receive(:new).with(
      changed_files: changed_files,
      rspec_test_mapping_path: temp_files[:coverage_mapping],
      logger: kind_of(Logger),
      rspec_mappings_limit_percentage: nil
    ).and_return(test_selector_coverage)

    allow(Tooling::PredictiveTests::TestSelector).to receive(:new).with(
      changed_files: changed_files,
      rspec_test_mapping_path: temp_files[:described_class_mapping],
      logger: kind_of(Logger),
      rspec_mappings_limit_percentage: nil
    ).and_return(test_selector_described)
  end

  context "when test_type is :backend" do
    let(:test_type) { :backend }
    let(:failed_tests_content) { "#{mappings.dig(:user, :spec)}\n#{mappings.dig(:todo, :spec)}" }

    it "uses mapping fetcher to get mapping json files" do
      exporter.execute

      expect(mapping_fetcher).to have_received(:fetch_rspec_mappings)
        .with(temp_files[:coverage_mapping], type: :coverage)
      expect(mapping_fetcher).to have_received(:fetch_rspec_mappings)
        .with(temp_files[:described_class_mapping], type: :described_class)
      expect(mapping_fetcher).to have_received(:fetch_frontend_fixtures_mappings)
        .with(temp_files[:frontend_fixtures])
    end

    it "exports described_class strategy metrics to ClickHouse", :aggregate_failures do
      exporter.execute

      expect_clickhouse_row(
        "described_class",
        changed_files_count: 4,
        predicted_test_files_count: 1,
        missed_failing_test_files: 1,
        predicted_failing_test_files: 1,
        failed_test_files_count: 2,
        projected_test_runtime_seconds: 2,
        test_files_missing_runtime_count: 0
      )
    end

    it "exports coverage strategy metrics to ClickHouse", :aggregate_failures do
      exporter.execute

      expect_clickhouse_row(
        "coverage",
        changed_files_count: 4,
        predicted_test_files_count: 3,
        missed_failing_test_files: 0,
        predicted_failing_test_files: 2,
        failed_test_files_count: 2,
        projected_test_runtime_seconds: 3,
        test_files_missing_runtime_count: 1
      )
    end

    it "creates metrics output files", :aggregate_failures do
      exporter.execute

      expect(read_metrics("coverage")).to eq({
        "test_type" => "backend",
        "strategy" => "coverage",
        "core_metrics" => {
          "changed_files_count" => 4,
          "failed_test_files_count" => 2,
          "missed_failing_test_files" => 0,
          "predicted_failing_test_files" => 2,
          "predicted_test_files_count" => 3,
          "runtime_metrics" => {
            "projected_test_runtime_seconds" => 3,
            "test_files_missing_runtime_count" => 1
          }
        }
      })
      expect(read_metrics("described_class")).to eq({
        "test_type" => "backend",
        "strategy" => "described_class",
        "core_metrics" => {
          "changed_files_count" => 4,
          "failed_test_files_count" => 2,
          "missed_failing_test_files" => 1,
          "predicted_failing_test_files" => 1,
          "predicted_test_files_count" => 1,
          "runtime_metrics" => {
            "projected_test_runtime_seconds" => 2,
            "test_files_missing_runtime_count" => 0
          }
        }
      })
    end

    context "with Duo metrics" do
      let(:duo_system_test_files_path) { File.join(input_dir, "duo_system_test_files.txt") }
      let(:feature_spec) { "spec/features/user_spec.rb" }
      let(:non_feature_spec) { "spec/models/user_spec.rb" }
      let(:failed_tests_content) { "#{feature_spec}\n#{non_feature_spec}" }

      before do
        stub_env("GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH" => duo_system_test_files_path)
        File.write(duo_system_test_files_path, feature_spec)
      end

      it "calculates misses against feature specs only, not all failures" do
        exporter.execute

        expect(read_metrics("duo")).to include(
          "core_metrics" => hash_including(
            "failed_test_files_count" => 1, # only the feature spec, not non_feature_spec
            "missed_failing_test_files" => 0,
            "predicted_failing_test_files" => 1
          )
        )
      end

      it "exports Duo metrics to ClickHouse", :aggregate_failures do
        exporter.execute

        expect_clickhouse_row(
          "duo",
          changed_files_count: 4,
          predicted_test_files_count: 1,
          missed_failing_test_files: 0,
          predicted_failing_test_files: 1,
          failed_test_files_count: 1,
          projected_test_runtime_seconds: 0,
          test_files_missing_runtime_count: 1
        )
      end

      context 'when GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH is not set' do
        before do
          stub_env('GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH' => nil)
        end

        it 'skips Duo metrics export without error' do
          expect { exporter.execute }.not_to raise_error
        end

        it 'does not create duo metrics file' do
          exporter.execute
          expect(File).not_to exist(File.join(output_dir, test_type.to_s, "metrics_duo.json"))
        end
      end

      context 'when artifact file does not exist' do
        before do
          stub_env('GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH' => '/nonexistent/duo.txt')
        end

        it 'skips without raising' do
          expect { exporter.execute }.not_to raise_error
        end
      end

      context 'when export_duo_metrics raises an error' do
        before do
          stub_env('GLCI_PREDICTIVE_DUO_SYSTEM_TESTS_PATH' => File.join(input_dir, 'duo.txt'))
          File.write(File.join(input_dir, 'duo.txt'), 'spec/features/user_spec.rb')
          allow(exporter).to receive(:generate_and_record_metrics).and_call_original
          allow(exporter).to receive(:generate_and_record_metrics)
                               .with(:duo, anything, scoped_failed_files: anything)
                               .and_raise(StandardError, 'boom')
        end

        it 'rescues and does not propagate the error' do
          expect { exporter.execute }.not_to raise_error
        end
      end
    end
  end

  context "when test_type is :frontend" do
    let(:test_type) { :frontend }
    let(:failed_tests_content) { "spec/frontend/project_spec.js\nspec/frontend/group_spec.js" }
    let(:changed_files_path) { File.join(Dir.tmpdir, "changed_files.txt") }
    let(:matching_js_files_path) { File.join(Dir.tmpdir, "matching_js_files.txt") }

    before do
      File.write(temp_files[:jest_matching_tests], jest_matching_tests.join(" "))

      allow(Open3).to receive(:capture2e).with({
        "GLCI_PREDICTIVE_CHANGED_FILES_PATH" => changed_files_path,
        'GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH' => matching_js_files_path,
        'JEST_MATCHING_TEST_FILES_PATH' => temp_files[:jest_matching_tests]
      }, %r{scripts/frontend/find_jest_predictive_tests.js})
      .and_return(["", instance_double(Process::Status, success?: true)])
    end

    it "creates inputs for predictive jest script" do
      exporter.execute

      # js predictive script has separate input for additional js files mapped from rails views
      expect(File.read(matching_js_files_path)).to eq(changed_js_files.join("\n"))
      expect(File.read(changed_files_path)).to eq(changed_files.select { |f| f.ends_with?(".rb") }.join("\n"))
    end

    it "exports jest_built_in strategy metrics to ClickHouse", :aggregate_failures do
      exporter.execute

      expect_clickhouse_row(
        "jest_built_in",
        changed_files_count: 4,
        predicted_test_files_count: 2,
        missed_failing_test_files: 1,
        predicted_failing_test_files: 1,
        failed_test_files_count: 2,
        projected_test_runtime_seconds: 0,
        test_files_missing_runtime_count: 0
      )
    end

    it "creates metrics output files", :aggregate_failures do
      exporter.execute

      expect(read_metrics("jest_built_in")).to eq({
        "test_type" => "frontend",
        "strategy" => "jest_built_in",
        "core_metrics" => {
          "changed_files_count" => 4,
          "failed_test_files_count" => 2,
          "predicted_failing_test_files" => 1,
          "missed_failing_test_files" => 1,
          "predicted_test_files_count" => 2
        }
      })
    end
  end

  context "when ClickHouse env vars are missing" do
    let(:test_type) { :backend }
    let(:failed_tests_content) { "#{mappings.dig(:user, :spec)}\n#{mappings.dig(:todo, :spec)}" }

    before do
      stub_env({
        "GLCI_DA_CLICKHOUSE_URL" => nil,
        "GLCI_CLICKHOUSE_METRICS_USERNAME" => nil,
        "GLCI_CLICKHOUSE_METRICS_PASSWORD" => nil,
        "GLCI_CLICKHOUSE_METRICS_DB" => nil,
        "GLCI_PREDICTIVE_TESTS_CLICKHOUSE_TABLE" => nil
      })
    end

    it "skips ClickHouse export and still succeeds" do
      expect(exporter.execute).to be true
    end

    it "does not instantiate ClickHouse client" do
      exporter.execute

      expect(GitlabQuality::TestTooling::ClickHouse::Client).not_to have_received(:new)
    end
  end

  context "when ClickHouse insert fails" do
    let(:test_type) { :backend }
    let(:failed_tests_content) { "#{mappings.dig(:user, :spec)}\n#{mappings.dig(:todo, :spec)}" }

    before do
      allow(clickhouse_client).to receive(:insert_json_data).and_raise(StandardError, "connection refused")
    end

    it "propagates the error as strategy failure" do
      expect(exporter.execute).to be false
    end
  end

  context "when test_type is invalid" do
    let(:test_type) { :invalid }

    it "raises an error" do
      expect { exporter }.to raise_error("Unknown test type 'invalid'")
    end
  end
end
# rubocop:enable Gitlab/Json
