# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FlushCounterIncrementsWorker, :counter_attribute do
  let(:project_statistics) { create(:project_statistics) }
  let(:model) { CounterAttributeModel.find(project_statistics.id) }

  describe '#perform', :redis do
    let(:attribute) { model.class.counter_attributes.first }
    let(:worker) { described_class.new }

    subject { worker.perform(model.class.name, model.id, attribute) }

    it 'flushes increments to database' do
      expect(model.class).to receive(:find_by_id).and_return(model)
      expect(model)
        .to receive(:flush_increments_to_database!)
        .with(attribute)
        .and_call_original

      subject
    end

    context 'when model class does not exist' do
      subject { worker.perform('non-existend-model') }

      it 'does nothing' do
        expect(worker).not_to receive(:in_lock)
      end
    end

    context 'when record does not exist' do
      subject { worker.perform(model.class.name, model.id + 100, attribute) }

      it 'does nothing' do
        expect(worker).not_to receive(:in_lock)
      end
    end
  end
end
