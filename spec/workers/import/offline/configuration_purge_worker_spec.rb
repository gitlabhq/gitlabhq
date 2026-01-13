# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ConfigurationPurgeWorker, feature_category: :importers do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when configuration exists' do
      let!(:configuration) { create(:import_offline_configuration) }

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { configuration.id }
      end

      it 'deletes the configuration' do
        expect { worker.perform(configuration.id) }.to change { Import::Offline::Configuration.count }.by(-1)
      end
    end

    context 'when configuration does not exist' do
      it 'returns early without raising an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
