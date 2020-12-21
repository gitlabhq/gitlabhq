# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experiments::RecordConversionEventWorker, '#perform' do
  subject(:perform) { described_class.new.perform(:experiment_key, 1234) }

  before do
    stub_experiment(experiment_key: experiment_active)
  end

  context 'when the experiment is active' do
    let(:experiment_active) { true }

    include_examples 'an idempotent worker' do
      subject { perform }

      it 'records the event' do
        expect(Experiment).to receive(:record_conversion_event).with(:experiment_key, 1234)

        perform
      end
    end
  end

  context 'when the experiment is not active' do
    let(:experiment_active) { false }

    it 'records the event' do
      expect(Experiment).not_to receive(:record_conversion_event)

      perform
    end
  end
end
