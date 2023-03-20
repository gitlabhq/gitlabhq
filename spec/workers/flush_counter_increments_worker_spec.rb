# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FlushCounterIncrementsWorker, :counter_attribute, feature_category: :shared do
  let(:project_statistics) { create(:project_statistics) }
  let(:model) { CounterAttributeModel.find(project_statistics.id) }

  describe '#perform', :redis do
    let(:attribute) { model.class.counter_attributes.first }
    let(:worker) { described_class.new }

    subject { worker.perform(model.class.name, model.id, attribute) }

    it 'commits increments to database' do
      expect(model.class).to receive(:find_by_id).and_return(model)
      expect_next_instance_of(Gitlab::Counters::BufferedCounter, model, attribute) do |service|
        expect(service).to receive(:commit_increment!)
      end

      subject
    end

    context 'when model class does not exist' do
      subject { worker.perform('NonExistentModel', 1, attribute) }

      it 'does nothing' do
        expect(Gitlab::Counters::BufferedCounter).not_to receive(:new)

        subject
      end
    end

    context 'when record does not exist' do
      subject { worker.perform(model.class.name, non_existing_record_id, attribute) }

      it 'does nothing' do
        expect(Gitlab::Counters::BufferedCounter).not_to receive(:new)

        subject
      end
    end
  end
end
