# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::QueueDurationLogger do
  subject { described_class.new }

  describe ".parameters" do
    let(:start_time) { Time.new(2018, 01, 01) }

    describe 'when no proxy duration is available' do
      let(:mock_request) { double('env', env: {}) }

      it 'returns an empty hash' do
        expect(subject.parameters(mock_request, nil)).to eq({})
      end
    end

    describe 'when a proxy duration is available' do
      let(:mock_request) do
        double('env',
          env: {
            'GITLAB_RAILS_QUEUE_DURATION' => 2.seconds
          }
        )
      end

      it 'adds the duration to log parameters' do
        travel_to(start_time) do
          expect(subject.parameters(mock_request, nil)).to eq({ queue_duration_s: 2.seconds.to_f })
        end
      end
    end
  end
end
