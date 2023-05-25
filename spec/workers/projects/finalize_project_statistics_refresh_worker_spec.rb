# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::FinalizeProjectStatisticsRefreshWorker, feature_category: :groups_and_projects do
  let_it_be(:record) { create(:project_build_artifacts_size_refresh, :finalizing) }

  describe '#perform' do
    let(:attribute) { record.class.counter_attributes.first }
    let(:worker) { described_class.new }

    subject { worker.perform(record.class.name, record.id) }

    it 'stores the refresh increment to the buffered counter' do
      expect(record.class).to receive(:find_by_id).and_return(record)
      expect(record).to receive(:finalize!)

      subject
    end

    context 'when record class does not exist' do
      subject { worker.perform('NonExistentModel', 1) }

      it 'does nothing' do
        expect(record).not_to receive(:finalize!)

        subject
      end
    end

    context 'when record does not exist' do
      subject { worker.perform(record.class.name, non_existing_record_id) }

      it 'does nothing' do
        expect(record).not_to receive(:finalize!)

        subject
      end
    end
  end
end
