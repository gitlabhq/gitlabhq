# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Terraform::Tfplan do
  describe '#parse!' do
    let_it_be(:artifact) { create(:ci_job_artifact, :terraform) }

    let(:reports) { Gitlab::Ci::Reports::TerraformReports.new }

    context 'when data is tfplan.json' do
      context 'when there is no data' do
        it 'raises an error' do
          plan = '{}'

          expect { subject.parse!(plan, reports, artifact: artifact) }.to raise_error(
            described_class::TfplanParserError
          )
        end
      end

      context 'when there is data' do
        it 'parses JSON and returns a report' do
          plan = '{ "create": 0, "update": 1, "delete": 0 }'

          expect { subject.parse!(plan, reports, artifact: artifact) }.not_to raise_error

          expect(reports.plans).to match(
            a_hash_including(
              'tfplan.json' => a_hash_including(
                'create' => 0,
                'update' => 1,
                'delete' => 0
              )
            )
          )
        end
      end
    end

    context 'when data is not tfplan.json' do
      it 'raises an error' do
        plan = { 'create' => 0, 'update' => 1, 'delete' => 0 }.to_s

        expect { subject.parse!(plan, reports, artifact: artifact) }.to raise_error(
          described_class::TfplanParserError
        )
      end
    end
  end
end
