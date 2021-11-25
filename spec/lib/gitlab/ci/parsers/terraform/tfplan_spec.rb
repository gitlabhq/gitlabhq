# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Terraform::Tfplan do
  describe '#parse!' do
    let(:artifact) { create(:ci_job_artifact, :terraform) }

    let(:reports) { Gitlab::Ci::Reports::TerraformReports.new }

    context 'when data is invalid' do
      context 'when data is not a JSON file' do
        it 'reports an invalid_json_format error' do
          plan = 'Not a JSON file'

          expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

          reports.plans.each do |key, hash_value|
            expect(hash_value.keys).to match_array(%w[job_id job_name job_path tf_report_error])
          end

          expect(reports.plans).to match(
            a_hash_including(
              artifact.job.id.to_s => a_hash_including(
                'tf_report_error' => :invalid_json_format
              )
            )
          )
        end
      end

      context 'when JSON is missing a required key' do
        it 'reports an invalid_json_keys error' do
          plan = '{ "wrong_key": 1 }'

          expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

          reports.plans.each do |key, hash_value|
            expect(hash_value.keys).to match_array(%w[job_id job_name job_path tf_report_error])
          end

          expect(reports.plans).to match(
            a_hash_including(
              artifact.job.id.to_s => a_hash_including(
                'tf_report_error' => :missing_json_keys
              )
            )
          )
        end
      end

      context 'when artifact is invalid' do
        it 'reports an :unknown_error' do
          expect { subject.parse!('{}', reports, artifact: nil) }.not_to raise_error

          reports.plans.each do |key, hash_value|
            expect(hash_value.keys).to match_array(%w[tf_report_error])
          end

          expect(reports.plans).to match(
            a_hash_including(
              'failed_tf_plan' => a_hash_including(
                'tf_report_error' => :unknown_error
              )
            )
          )
        end
      end

      context 'when job is invalid' do
        it 'reports an :unknown_error' do
          artifact.job_id = nil
          expect { subject.parse!('{}', reports, artifact: artifact) }.not_to raise_error

          reports.plans.each do |key, hash_value|
            expect(hash_value.keys).to match_array(%w[tf_report_error])
          end

          expect(reports.plans).to match(
            a_hash_including(
              'failed_tf_plan' => a_hash_including(
                'tf_report_error' => :unknown_error
              )
            )
          )
        end
      end
    end

    context 'when data is valid' do
      it 'parses JSON and returns a report' do
        plan = '{ "create": 0, "update": 1, "delete": 0 }'

        expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

        reports.plans.each do |key, hash_value|
          expect(hash_value.keys).to match_array(%w[create delete job_id job_name job_path update])
        end

        expect(reports.plans).to match(
          a_hash_including(
            artifact.job.id.to_s => a_hash_including(
              'create' => 0,
              'update' => 1,
              'delete' => 0,
              'job_name' => artifact.job.name
            )
          )
        )
      end

      it 'parses JSON when extra keys are present' do
        plan = '{ "create": 0, "update": 1, "delete": 0, "extra_key": 4 }'

        expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

        reports.plans.each do |key, hash_value|
          expect(hash_value.keys).to match_array(%w[create delete job_id job_name job_path update])
        end

        expect(reports.plans).to match(
          a_hash_including(
            artifact.job.id.to_s => a_hash_including(
              'create' => 0,
              'update' => 1,
              'delete' => 0,
              'job_name' => artifact.job.name
            )
          )
        )
      end
    end
  end
end
