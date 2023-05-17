# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Counters::CleanupRefreshWorker, feature_category: :shared do
  let(:model) { create(:project_statistics) }

  describe '#perform', :redis do
    let(:attribute) { :build_artifacts_size }
    let(:worker) { described_class.new }

    subject { worker.perform(model.class.name, model.id, attribute) }

    it 'calls cleanup_refresh on the counter' do
      expect_next_instance_of(Gitlab::Counters::BufferedCounter, model, attribute) do |counter|
        expect(counter).to receive(:cleanup_refresh)
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
