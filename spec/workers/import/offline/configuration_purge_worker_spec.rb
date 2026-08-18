# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ConfigurationPurgeWorker, feature_category: :importers do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when configuration exists' do
      let(:configuration) { create(:import_offline_configuration) }

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { configuration.id }
      end

      it 'clears the credentials and preserves the configuration', :aggregate_failures do
        preserved_attributes = configuration.attributes.slice('provider', 'bucket', 'export_prefix', 'source_hostname')

        expect { worker.perform(configuration.id) }
          .to change { configuration.reload.object_storage_credentials }.to({})
          .and not_change { Import::Offline::Configuration.count }

        expect(configuration.reload.attributes).to include(preserved_attributes)
      end

      context 'when the provider is S3-compatible' do
        let(:configuration) { create(:import_offline_configuration, :s3_compatible) }

        before do
          stub_application_setting(allow_s3_compatible_storage_for_offline_transfer: true)
        end

        it 'clears the credentials' do
          expect { worker.perform(configuration.id) }
            .to change { configuration.reload.object_storage_credentials }.to({})
        end
      end
    end

    context 'when configuration does not exist' do
      it 'returns early without raising an error' do
        expect { worker.perform(non_existing_record_id) }.not_to raise_error
      end
    end
  end
end
