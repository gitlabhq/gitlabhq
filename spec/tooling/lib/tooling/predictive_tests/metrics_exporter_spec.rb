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
      rspec_all_failed_tests_file: failed_tests_file,
      crystalball_mapping_dir: input_dir,
      frontend_fixtures_mapping_file: frontend_fixtures_file,
      output_dir: output_dir
    )
  end

  let(:event_tracker) { instance_double(Tooling::Events::TrackPipelineEvents, send_event: nil) }
  let(:test_selector) { instance_double(Tooling::PredictiveTests::TestSelector, execute: nil) }
  let(:logger) { instance_double(Logger, info: nil, error: nil) }

  let(:event_name) { "glci_predictive_tests_metrics" }
  let(:extra_properties) { { ci_job_id: "123" } }

  # temporary folder for inputs and outputs
  let(:input_dir) { Dir.mktmpdir("predictive-tests-input") }
  let(:output_dir) { Dir.mktmpdir("predictive-tests-output") }
  # various input files used by MetricsExporter to create metrics output
  let(:coverage_mapping_file) { File.join(input_dir, "coverage", "mapping.json") }
  let(:described_class_mapping_file) { File.join(input_dir, "described_class", "mapping.json") }
  let(:failed_tests_file) { File.join(input_dir, "failed_test.txt") }
  let(:frontend_fixtures_file) { File.join(input_dir, "frontend_fixtures.json") }
  # output files created by TestSelector and used by MetricsExporter to create metrics output
  let(:matching_tests_coverage_file) { File.join(output_dir, "coverage", "rspec_matching_test_files.txt") }
  let(:matching_tests_described_class_file) do
    File.join(output_dir, "described_class", "rspec_matching_test_files.txt")
  end

  let(:mappings) do
    {
      user: { model: "app/models/user.rb", spec: "spec/models/user_spec.rb" },
      todo: { model: "app/models/todo.rb", spec: "spec/models/todo_spec.rb" },
      project: { model: "app/models/project.rb", spec: "spec/models/project_spec.rb" }
    }
  end

  let(:changed_files) { mappings.values.pluck(:model) }
  let(:matching_tests_described_class_content) { mappings.dig(:user, :spec) }
  let(:matching_tests_coverage_content) { mappings.values.pluck(:spec).join(" ") }
  let(:failed_tests_content) { "#{mappings.dig(:user, :spec)}\n#{mappings.dig(:todo, :spec)}" }

  let(:described_class_mapping_content) do
    { mappings.dig(:user, :model) => [mappings.dig(:user, :spec)] }.to_json
  end

  let(:coverage_mapping_content) do
    mappings.values.to_h { |mapping| [mapping[:model], [mapping[:spec]]] }.to_json
  end

  def read_metrics(strategy)
    JSON.parse(File.read(File.join(output_dir, "metrics_#{strategy}.json"))).except("timestamp")
  end

  def expect_events_sent(strategy, changed_files_count:, predicted_test_files_count:, missed_failing_test_files:)
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
  end

  before do
    stub_env({ "CI_JOB_ID" => extra_properties[:ci_job_id] })

    # create folders for separate strategies
    [input_dir, output_dir].each do |dir|
      FileUtils.mkdir_p(File.join(dir, "coverage"))
      FileUtils.mkdir_p(File.join(dir, "described_class"))
    end

    # create files used as input for exporting selected test metrics
    File.write(failed_tests_file, failed_tests_content)
    File.write(matching_tests_described_class_file, matching_tests_described_class_content)
    File.write(matching_tests_coverage_file, matching_tests_coverage_content)
    File.write(coverage_mapping_file, coverage_mapping_content)
    File.write(described_class_mapping_file, described_class_mapping_content)

    allow(Tooling::PredictiveTests::ChangedFiles).to receive(:fetch)
      .with(frontend_fixtures_file: frontend_fixtures_file)
      .and_return(changed_files)
    allow(Tooling::PredictiveTests::TestSelector).to receive(:new).and_return(test_selector)
    allow(Tooling::Events::TrackPipelineEvents).to receive(:new).and_return(event_tracker)
    allow(Logger).to receive(:new).with($stdout, progname: "predictive testing").and_return(logger)
  end

  describe "#execute" do
    it "creates selected test list for each strategy" do
      exporter.execute

      expect(Tooling::PredictiveTests::TestSelector).to have_received(:new).with(
        changed_files: changed_files,
        rspec_test_mapping_path: coverage_mapping_file,
        rspec_matching_test_files_path: matching_tests_coverage_file,
        rspec_matching_js_files_path: File.join(output_dir, "coverage", "js_matching_files.txt"),
        rspec_mappings_limit_percentage: nil
      )
      expect(Tooling::PredictiveTests::TestSelector).to have_received(:new).with(
        changed_files: changed_files,
        rspec_test_mapping_path: described_class_mapping_file,
        rspec_matching_test_files_path: matching_tests_described_class_file,
        rspec_matching_js_files_path: File.join(output_dir, "described_class", "js_matching_files.txt"),
        rspec_mappings_limit_percentage: nil
      )
      expect(test_selector).to have_received(:execute).twice
    end

    it "exports metrics for described_class strategy", :aggregate_failures do
      exporter.execute

      expect_events_sent(
        "described_class",
        changed_files_count: 3,
        predicted_test_files_count: 1,
        missed_failing_test_files: 1
      )
    end

    it "exports metrics for coverage strategy", :aggregate_failures do
      exporter.execute

      expect_events_sent(
        "coverage",
        changed_files_count: 3,
        predicted_test_files_count: 3,
        missed_failing_test_files: 0
      )
    end

    it "creates metrics output files", :aggregate_failures do
      exporter.execute

      expect(read_metrics("coverage")).to eq({
        "strategy" => "coverage",
        "core_metrics" => {
          "changed_files_count" => 3,
          "changed_files_in_mapping" => 3,
          "failed_test_files_count" => 2,
          "missed_failing_test_files" => 0,
          "predicted_test_files_count" => 3
        },
        "mapping_metrics" => {
          "failed_test_files_in_mapping" => 2,
          "test_files_selected_by_crystalball" => 3,
          "total_test_files_in_mapping" => 3
        }
      })
      expect(read_metrics("described_class")).to eq({
        "strategy" => "described_class",
        "core_metrics" => {
          "changed_files_count" => 3,
          "changed_files_in_mapping" => 1,
          "failed_test_files_count" => 2,
          "missed_failing_test_files" => 1,
          "predicted_test_files_count" => 1
        },
        "mapping_metrics" => {
          "failed_test_files_in_mapping" => 1,
          "test_files_selected_by_crystalball" => 1,
          "total_test_files_in_mapping" => 1
        }
      })
    end
  end
end
# rubocop:enable Gitlab/Json
