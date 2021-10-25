# frozen_string_literal: true

require 'spec_helper'
require_relative '../../scripts/pipeline_test_report_builder'

RSpec.describe PipelineTestReportBuilder do
  let(:report_file) { 'spec/fixtures/scripts/test_report.json' }
  let(:output_file_path) { 'tmp/previous_test_results/output_file.json' }

  subject do
    described_class.new(
      project: 'gitlab-org/gitlab',
      mr_id: '999',
      instance_base_url: 'https://gitlab.com',
      output_file_path: output_file_path
    )
  end

  let(:mr_pipelines) do
    [
      {
        'status' => 'running',
        'created_at' => DateTime.now.to_s
      },
      {
        'status' => 'failed',
        'created_at' => (DateTime.now - 5).to_s
      }
    ]
  end

  let(:failed_builds_for_pipeline) do
    [
      {
        'id' => 9999,
        'stage' => 'test'
      }
    ]
  end

  let(:test_report_for_build) do
    {
      "name": "rspec-ee system pg11 geo",
      "failed_count": 41,
      "test_cases": [
        {
          "status": "failed",
          "name": "example",
          "classname": "ee.spec.features.geo_node_spec",
          "file": "./ee/spec/features/geo_node_spec.rb",
          "execution_time": 6.324748,
          "system_output": {
            "__content__": "\n",
            "message": "RSpec::Core::MultipleExceptionError",
            "type": "RSpec::Core::MultipleExceptionError"
          }
        }
      ]
    }
  end

  before do
    allow(subject).to receive(:pipelines_for_mr).and_return(mr_pipelines)
    allow(subject).to receive(:failed_builds_for_pipeline).and_return(failed_builds_for_pipeline)
    allow(subject).to receive(:test_report_for_build).and_return(test_report_for_build)
  end

  describe '#test_report_for_latest_pipeline' do
    context 'no previous pipeline' do
      let(:mr_pipelines) { [] }

      it 'returns empty hash' do
        expect(subject.test_report_for_latest_pipeline).to eq("{}")
      end
    end

    context 'first pipeline scenario' do
      let(:mr_pipelines) do
        [
          {
            'status' => 'running',
            'created_at' => DateTime.now.to_s
          }
        ]
      end

      it 'returns empty hash' do
        expect(subject.test_report_for_latest_pipeline).to eq("{}")
      end
    end

    context 'no previous failed pipeline' do
      let(:mr_pipelines) do
        [
          {
            'status' => 'running',
            'created_at' => DateTime.now.to_s
          },
          {
            'status' => 'success',
            'created_at' => (DateTime.now - 5).to_s
          }
        ]
      end

      it 'returns empty hash' do
        expect(subject.test_report_for_latest_pipeline).to eq("{}")
      end
    end

    context 'no failed test builds' do
      let(:failed_builds_for_pipeline) do
        [
          {
            'id' => 9999,
            'stage' => 'prepare'
          }
        ]
      end

      it 'returns empty hash' do
        expect(subject.test_report_for_latest_pipeline).to eq("{}")
      end
    end

    context 'failed pipeline and failed test builds' do
      it 'returns populated test list for suites' do
        actual = subject.test_report_for_latest_pipeline
        expected = {
          'suites' => [test_report_for_build]
        }.to_json

        expect(actual).to eq(expected)
      end
    end
  end
end
