# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::UsageTrends::CountJobTriggerWorker do
  it_behaves_like 'an idempotent worker'

  context 'triggers a job for each measurement identifiers' do
    let(:expected_count) { Analytics::UsageTrends::Measurement.identifier_query_mapping.keys.size }

    it 'triggers CounterJobWorker jobs' do
      subject.perform

      expect(Analytics::UsageTrends::CounterJobWorker.jobs.count).to eq(expected_count)
    end
  end
end
