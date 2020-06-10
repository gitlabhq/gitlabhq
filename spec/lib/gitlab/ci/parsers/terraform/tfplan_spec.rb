# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Terraform::Tfplan do
  describe '#parse!' do
    let_it_be(:artifact) { create(:ci_job_artifact, :terraform) }

    let(:reports) { Gitlab::Ci::Reports::TerraformReports.new }

    context 'when data is invalid' do
      context 'when there is no data' do
        it 'raises an error' do
          plan = '{}'

          expect { subject.parse!(plan, reports, artifact: artifact) }.to raise_error(
            described_class::TfplanParserError
          )
        end
      end

      context 'when data is not a JSON file' do
        it 'raises an error' do
          plan = { 'create' => 0, 'update' => 1, 'delete' => 0 }.to_s

          expect { subject.parse!(plan, reports, artifact: artifact) }.to raise_error(
            described_class::TfplanParserError
          )
        end
      end

      context 'when JSON is missing a required key' do
        it 'raises an error' do
          plan = '{ "wrong_key": 1 }'

          expect { subject.parse!(plan, reports, artifact: artifact) }.to raise_error(
            described_class::TfplanParserError
          )
        end
      end
    end

    context 'when data is valid' do
      it 'parses JSON and returns a report' do
        plan = '{ "create": 0, "update": 1, "delete": 0 }'

        expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

        reports.plans.each do |key, hash_value|
          expect(hash_value.keys).to match_array(%w[create delete job_name job_path update])
        end

        expect(reports.plans).to match(
          a_hash_including(
            artifact.job.id.to_s => a_hash_including(
              'create' => 0,
              'update' => 1,
              'delete' => 0,
              'job_name' => artifact.job.options.dig(:artifacts, :name).to_s
            )
          )
        )
      end

      it 'parses JSON when extra keys are present' do
        plan = '{ "create": 0, "update": 1, "delete": 0, "extra_key": 4 }'

        expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

        reports.plans.each do |key, hash_value|
          expect(hash_value.keys).to match_array(%w[create delete job_name job_path update])
        end

        expect(reports.plans).to match(
          a_hash_including(
            artifact.job.id.to_s => a_hash_including(
              'create' => 0,
              'update' => 1,
              'delete' => 0,
              'job_name' => artifact.job.options.dig(:artifacts, :name).to_s
            )
          )
        )
      end
    end
  end
end
