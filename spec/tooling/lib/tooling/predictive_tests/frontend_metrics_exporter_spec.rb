# frozen_string_literal: true

# rubocop:disable Gitlab/Json -- no Rails environment

require "tempfile"
require "fileutils"
require "fast_spec_helper"

require_relative "../../../../../tooling/lib/tooling/predictive_tests/frontend_metrics_exporter"

RSpec.describe Tooling::PredictiveTests::FrontendMetricsExporter, feature_category: :tooling do
  include StubENV

  subject(:exporter) do
    described_class.new(
      rspec_changed_files_path: changed_files_path,
      rspec_matching_js_files_path: rspec_matching_js_files_path,
      jest_failed_test_files_path: jest_failed_tests_path,
      output_dir: output_dir
    )
  end

  let(:event_tracker) { instance_double(Tooling::Events::TrackPipelineEvents, send_event: nil) }
  let(:logger) { instance_double(Logger, info: nil, error: nil, warn: nil) }

  let(:output_dir) { Dir.mktmpdir("predictive-tests-output") }
  let(:changed_files_path) { create_temp_file("changed_files.txt", changed_files_content) }
  let(:rspec_matching_js_files_path) { create_temp_file("matching_js.txt", matching_js_files_content) }
  let(:jest_failed_tests_path) { create_temp_file("failed_tests.txt", failed_tests_content) }

  let(:changed_files_content) do
    "app/assets/javascripts/issues/show.js app/models/user.rb " \
      "ee/app/assets/javascripts/security/scanner.vue spec/frontend/issues/show_spec.js"
  end

  let(:matching_js_files_content) do
    "app/assets/javascripts/pages/projects/merge_requests/show/index.js " \
      "ee/app/assets/javascripts/security_dashboard/coponents/app.vue"
  end

  let(:failed_tests_content) do
    "spec/frontend/issues/show_spec.js spec/frontend/security/scanner_spec.js " \
      "spec/frontend/not_predicted_spec.js"
  end

  let(:predicted_tests_content) do
    "spec/frontend/issues/show_spec.js " \
      "spec/frontend/security/scanner_spec.js"
  end

  let(:jest_script_path) { "scripts/frontend/find_jest_predictive_tests.js" }
  let(:event_name) { "glci_predictive_tests_metrics" }
  let(:extra_properties) { { ci_job_id: "123456", test_type: "frontend" } }

  before do
    stub_env({ "CI_JOB_ID" => extra_properties[:ci_job_id] })

    allow(Tooling::Events::TrackPipelineEvents).to receive(:new).and_return(event_tracker)
    allow(Logger).to receive(:new).and_return(logger)
  end

  after do
    FileUtils.rm_rf(output_dir)
    [changed_files_path, rspec_matching_js_files_path, jest_failed_tests_path].each do |path|
      FileUtils.rm_f(path) if path && File.exist?(path)
    end
  end

  describe "#execute" do
    context "with successful Jest script execution" do
      let(:expected_env) do
        {
          'RSPEC_CHANGED_FILES_PATH' => changed_files_path,
          'RSPEC_MATCHING_JS_FILES_PATH' => rspec_matching_js_files_path,
          'JEST_MATCHING_TEST_FILES_PATH' => match(%r{frontend/jest_matching_test_files\.txt$})
        }
      end

      before do
        mock_jest_script_execution(success: true, create_output: true)
      end

      it "calls Jest script with correct environment variables" do
        exporter.execute

        expect(exporter).to have_received(:system).with(
          hash_including(expected_env),
          anything
        )
      end

      it "generates Jest predictive test list", :aggregate_failures do
        exporter.execute

        jest_output_path = File.join(output_dir, "frontend", "jest_matching_test_files.txt")
        expect(File.exist?(jest_output_path)).to be true
        expect(File.read(jest_output_path).split(" ")).to contain_exactly(
          "spec/frontend/issues/show_spec.js",
          "spec/frontend/security/scanner_spec.js"
        )
      end

      it "creates metrics JSON file with correct content", :aggregate_failures do
        exporter.execute

        metrics_path = File.join(output_dir, "frontend", "metrics_frontend.json")
        expect(File.exist?(metrics_path)).to be true

        metrics = JSON.parse(File.read(metrics_path))
        expect(metrics).to include(
          "test_framework" => "jest",
          "timestamp" => be_a(String),
          "core_metrics" => {
            "changed_files_count" => 4,
            "predicted_test_files_count" => 2,
            "missed_failing_test_files" => 1, # not_predicted_spec.js
            "changed_js_files_count" => 3, # .js, .vue, but not .rb
            "backend_triggered_js_files_count" => 2
          }
        )
      end

      it "sends correct events to tracker", :aggregate_failures do
        exporter.execute

        expect(event_tracker).to have_received(:send_event).exactly(3).times

        expect(event_tracker).to have_received(:send_event).with(
          event_name,
          label: "changed_files_count",
          value: 4,
          property: "jest_built_in",
          extra_properties: extra_properties
        )

        expect(event_tracker).to have_received(:send_event).with(
          event_name,
          label: "predicted_test_files_count",
          value: 2,
          property: "jest_built_in",
          extra_properties: extra_properties
        )

        expect(event_tracker).to have_received(:send_event).with(
          event_name,
          label: "missed_failing_test_files",
          value: 1,
          property: "jest_built_in",
          extra_properties: extra_properties
        )
      end
    end

    context "with failed Jest script execution" do
      before do
        mock_jest_script_execution(success: false)
      end

      it "rescues the error and logs failure" do
        expect { exporter.execute }.not_to raise_error
        expect(logger).to have_received(:error).with("Failed to generate Jest predictive tests")
        expect(logger).to have_received(:info).with("Skipping metrics export due to Jest script issues")
      end

      it "does not send any events" do
        exporter.execute

        expect(event_tracker).not_to have_received(:send_event)
      end
    end

    context "when Jest script is missing" do
      before do
        script_path_pattern = /find_jest_predictive_tests\.js$/
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(script_path_pattern).and_return(false)
      end

      it "logs warning and skips metrics without raising error" do
        expect { exporter.execute }.not_to raise_error
        expect(logger).to have_received(:warn).with(/Jest predictive test script not found/)
        expect(logger).to have_received(:info).with("Skipping metrics export due to Jest script issues")
      end

      it "does not send any events" do
        exporter.execute

        expect(event_tracker).not_to have_received(:send_event)
      end
    end

    context "with empty input files" do
      let(:changed_files_content) { "" }
      let(:matching_js_files_content) { "" }
      let(:failed_tests_content) { "" }
      let(:predicted_tests_content) { "" }

      before do
        mock_jest_script_execution(success: true)
      end

      it "handles empty files gracefully", :aggregate_failures do
        exporter.execute

        metrics_path = File.join(output_dir, "frontend", "metrics_frontend.json")
        metrics = JSON.parse(File.read(metrics_path))

        expect(metrics["core_metrics"]).to eq({
          "changed_files_count" => 0,
          "predicted_test_files_count" => 0,
          "missed_failing_test_files" => 0,
          "changed_js_files_count" => 0,
          "backend_triggered_js_files_count" => 0
        })
      end
    end

    context "when metrics save fails" do
      before do
        mock_jest_script_execution(success: true)

        allow(File).to receive(:write).and_call_original
        allow(File).to receive(:write).with(/metrics_frontend\.json/, anything).and_raise(Errno::EACCES)
      end

      it "logs the error but does not raise" do
        expect { exporter.execute }.not_to raise_error

        expect(logger).to have_received(:error).with(/Failed to export frontend metrics.*Permission denied/)
        expect(logger).to have_received(:error).with(array_including(/tooling/))
      end
    end
  end

  private

  def create_temp_file(name, content)
    file = Tempfile.new(name)
    file.write(content)
    file.close
    file.path
  end

  def mock_jest_script_execution(success: true, create_output: true)
    allow(exporter).to receive(:system) do |env, _|
      if success && create_output
        jest_output_path = env['JEST_MATCHING_TEST_FILES_PATH']
        FileUtils.mkdir_p(File.dirname(jest_output_path))
        File.write(jest_output_path, predicted_tests_content)
      end

      success
    end
  end
end
# rubocop:enable Gitlab/Json
