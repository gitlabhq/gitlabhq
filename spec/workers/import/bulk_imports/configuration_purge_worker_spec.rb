# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::ConfigurationPurgeWorker, feature_category: :importers do
  describe '#perform' do
    let(:bulk_import) { create(:bulk_import, :with_configuration, :finished) }
    let(:configuration) { bulk_import.configuration }
    let(:id) { configuration.id }

    let(:worker) { described_class.new }

    context 'when bulk import configuration exists' do
      it_behaves_like 'an idempotent worker' do
        let(:job_args) { id }
        it 'nullifies access token' do
          expect { worker.perform(id) }.to change { configuration.reload.access_token }.to(nil)
        end
      end
    end

    context 'when bulk import configuration does not exist' do
      it 'returns early without raising an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
