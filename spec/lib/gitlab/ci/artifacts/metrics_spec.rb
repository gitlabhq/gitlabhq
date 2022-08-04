# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Artifacts::Metrics, :prometheus do
  let(:metrics) { described_class.new }

  describe '.build_completed_report_type_counter' do
    context 'when incrementing by more than one' do
      let(:sast_counter) { described_class.send(:build_completed_report_type_counter, :sast) }
      let(:dast_counter) { described_class.send(:build_completed_report_type_counter, :dast) }

      it 'increments a single counter' do
        [dast_counter, sast_counter].each do |counter|
          counter.increment(status: 'success')
          counter.increment(status: 'success')
          counter.increment(status: 'failed')

          expect(counter.get(status: 'success')).to eq 2.0
          expect(counter.get(status: 'failed')).to eq 1.0
          expect(counter.values.count).to eq 2
        end
      end
    end
  end

  describe '#increment_destroyed_artifacts' do
    context 'when incrementing by more than one' do
      let(:counter) { metrics.send(:destroyed_artifacts_counter) }

      it 'increments a single counter' do
        subject.increment_destroyed_artifacts_count(10)
        subject.increment_destroyed_artifacts_count(20)
        subject.increment_destroyed_artifacts_count(30)

        expect(counter.get).to eq 60
        expect(counter.values.count).to eq 1
      end
    end
  end
end
