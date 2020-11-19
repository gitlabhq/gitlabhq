# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::InstanceStatistics::CountJobTriggerWorker do
  it_behaves_like 'an idempotent worker'

  context 'triggers a job for each measurement identifiers' do
    let(:expected_count) { Analytics::InstanceStatistics::Measurement.identifier_query_mapping.keys.size }

    it 'triggers CounterJobWorker jobs' do
      subject.perform

      expect(Analytics::InstanceStatistics::CounterJobWorker.jobs.count).to eq(expected_count)
    end
  end
end
