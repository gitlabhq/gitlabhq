# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Prometheus::Queries::AdditionalMetricsEnvironmentQuery do
  around do |example|
    freeze_time { example.run }
  end

  include_examples 'additional metrics query' do
    let(:query_params) { [environment.id] }

    it 'queries using specific time' do
      expect(client).to receive(:query_range)
        .with(anything, start_time: 8.hours.ago.to_f, end_time: Time.now.to_f)
      expect(query_result).not_to be_nil
    end

    context 'when start and end time parameters are provided' do
      let(:query_params) { [environment.id, start_time, end_time] }

      context 'as unix timestamps' do
        let(:start_time) { 4.hours.ago.to_f }
        let(:end_time) { 2.hours.ago.to_f }

        it 'queries using the provided times' do
          expect(client).to receive(:query_range)
            .with(anything, start_time: start_time, end_time: end_time)
          expect(query_result).not_to be_nil
        end
      end

      context 'as Date/Time objects' do
        let(:start_time) { 4.hours.ago }
        let(:end_time) { 2.hours.ago }

        it 'queries using the provided times converted to unix' do
          expect(client).to receive(:query_range)
            .with(anything, start_time: start_time.to_f, end_time: end_time.to_f)
          expect(query_result).not_to be_nil
        end
      end
    end
  end
end
