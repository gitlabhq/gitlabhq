# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Artifacts::Metrics, :prometheus do
  let(:metrics) { described_class.new }

  describe '#increment_destroyed_artifacts' do
    context 'when incrementing by more than one' do
      let(:counter) { metrics.send(:destroyed_artifacts_counter) }

      it 'increments a single counter' do
        subject.increment_destroyed_artifacts(10)
        subject.increment_destroyed_artifacts(20)
        subject.increment_destroyed_artifacts(30)

        expect(counter.get).to eq 60
        expect(counter.values.count).to eq 1
      end
    end
  end
end
