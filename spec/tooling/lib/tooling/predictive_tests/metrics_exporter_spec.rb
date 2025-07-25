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

  let(:event_tracker) { instance_double(Tooling::Events::TrackPipelineEvents, send_event: nil) }

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

  let(:event_name) { "glci_predictive_tests_metrics" }
  let(:test_type) { :backend }
  let(:extra_properties) { { ci_job_id: "123", test_type: test_type, ci_pipeline_id: "321" } }

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

  def expect_events_sent(
    strategy, changed_files_count:, predicted_test_files_count:, missed_failing_test_files:,
    projected_test_runtime_seconds: nil,
    test_files_missing_runtime_count: nil)
    expect(event_tracker).to have_received(:send_event).with(
      event_name,
      label: "changed_files_count",
      value: changed_files_count,
      property: strategy,
      extra_properties: extra_properties
    )
    expect(event_tracker).to have_received(:send_event).with(
      event_name,
      label: "predicted_test_files_count",
      value: predicted_test_files_count,
      property: strategy,
      extra_properties: extra_properties
    )
    expect(event_tracker).to have_received(:send_event).with(
      event_name,
      label: "missed_failing_test_files",
      value: missed_failing_test_files,
      property: strategy,
      extra_properties: extra_properties
    )

    return unless projected_test_runtime_seconds && test_files_missing_runtime_count

    expect(event_tracker).to have_received(:send_event).with(
      event_name,
      label: "projected_test_runtime_seconds",
      value: projected_test_runtime_seconds,
      property: strategy,
      extra_properties: extra_properties
    )
    expect(event_tracker).to have_received(:send_event).with(
      event_name,
      label: "test_files_missing_runtime_count",
      value: test_files_missing_runtime_count,
      property: strategy,
      extra_properties: extra_properties
    )
  end

  before do
    stub_env({ "CI_JOB_ID" => extra_properties[:ci_job_id], "CI_PIPELINE_ID" => extra_properties[:ci_pipeline_id] })

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
    allow(Tooling::Events::TrackPipelineEvents).to receive(:new).with(logger: kind_of(Logger)).and_return(event_tracker)
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

    it "exports metrics for described_class strategy", :aggregate_failures do
      exporter.execute

      expect_events_sent(
        "described_class",
        changed_files_count: 4,
        predicted_test_files_count: 1,
        missed_failing_test_files: 1,
        projected_test_runtime_seconds: 2,
        test_files_missing_runtime_count: 0
      )
    end

    it "exports metrics for coverage strategy", :aggregate_failures do
      exporter.execute

      expect_events_sent(
        "coverage",
        changed_files_count: 4,
        predicted_test_files_count: 3,
        missed_failing_test_files: 0,
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
          "predicted_test_files_count" => 1,
          "runtime_metrics" => {
            "projected_test_runtime_seconds" => 2,
            "test_files_missing_runtime_count" => 0
          }
        }
      })
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

    it "exports metrics for jest_built_in strategy", :aggregate_failures do
      exporter.execute

      expect_events_sent(
        "jest_built_in",
        changed_files_count: 4,
        predicted_test_files_count: 2,
        missed_failing_test_files: 1
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
          "missed_failing_test_files" => 1,
          "predicted_test_files_count" => 2
        }
      })
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
