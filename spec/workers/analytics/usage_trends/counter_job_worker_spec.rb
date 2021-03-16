# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::UsageTrends::CounterJobWorker do
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }

  let(:users_measurement_identifier) { ::Analytics::UsageTrends::Measurement.identifiers.fetch(:users) }
  let(:recorded_at) { Time.zone.now }
  let(:job_args) { [users_measurement_identifier, user_1.id, user_2.id, recorded_at] }

  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  include_examples 'an idempotent worker' do
    it 'counts a scope and stores the result' do
      subject

      measurement = Analytics::UsageTrends::Measurement.users.first
      expect(measurement.recorded_at).to be_like_time(recorded_at)
      expect(measurement.identifier).to eq('users')
      expect(measurement.count).to eq(2)
    end
  end

  context 'when no records are in the database' do
    let(:users_measurement_identifier) { ::Analytics::UsageTrends::Measurement.identifiers.fetch(:groups) }

    subject { described_class.new.perform(users_measurement_identifier, nil, nil, recorded_at) }

    it 'sets 0 as the count' do
      subject

      measurement = Analytics::UsageTrends::Measurement.groups.first
      expect(measurement.recorded_at).to be_like_time(recorded_at)
      expect(measurement.identifier).to eq('groups')
      expect(measurement.count).to eq(0)
    end
  end

  it 'does not raise error when inserting duplicated measurement' do
    subject

    expect { subject }.not_to raise_error
  end

  it 'does not insert anything when BatchCount returns error' do
    allow(Gitlab::Database::BatchCount).to receive(:batch_count).and_return(Gitlab::Database::BatchCounter::FALLBACK)

    expect { subject }.not_to change { Analytics::UsageTrends::Measurement.count }
  end

  context 'when pipelines_succeeded identifier is passed' do
    let_it_be(:pipeline) { create(:ci_pipeline, :success) }

    let(:successful_pipelines_measurement_identifier) { ::Analytics::UsageTrends::Measurement.identifiers.fetch(:pipelines_succeeded) }
    let(:job_args) { [successful_pipelines_measurement_identifier, pipeline.id, pipeline.id, recorded_at] }

    it 'counts successful pipelines' do
      subject

      measurement = Analytics::UsageTrends::Measurement.pipelines_succeeded.first
      expect(measurement.recorded_at).to be_like_time(recorded_at)
      expect(measurement.identifier).to eq('pipelines_succeeded')
      expect(measurement.count).to eq(1)
    end
  end
end
