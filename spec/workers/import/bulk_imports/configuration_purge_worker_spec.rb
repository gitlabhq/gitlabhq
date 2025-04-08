# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::ConfigurationPurgeWorker, feature_category: :importers do
  describe '#perform' do
    let_it_be(:bulk_import) { create(:bulk_import, :with_configuration, :finished) }
    let_it_be(:configuration) { bulk_import.configuration }
    let_it_be(:id) { configuration.id }

    let(:worker) { described_class.new }

    context 'when bulk import exists and is completed' do
      before do
        allow(::BulkImports::Configuration).to receive(:find_by_id).with(id).and_return(configuration)
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { id }
        it 'purges the configuration' do
          expect(configuration).to receive(:destroy!)

          worker.perform(id)
        end
      end

      context 'when purge raises RecordNotDestroyed error' do
        let(:logger_attributes) { { foo: 'bar' } }
        let(:error) { ActiveRecord::RecordNotDestroyed.new('', configuration) }
        let(:expected_attributes) do
          {
            message: "Failed to purge bulk import configuration due to errors",
            foo: 'bar'
          }
        end

        before do
          allow(worker).to receive_message_chain(:logger, :default_attributes).and_return(logger_attributes)
          allow(configuration).to receive(:destroy!).and_raise(error)
        end

        it 'tracks the exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
            error,
            expected_attributes
          )

          worker.perform(id)
        end
      end
    end

    context 'when bulk import does not exist' do
      before do
        allow(::BulkImports::Configuration).to receive(:find_by_id).with(id).and_return(nil)
      end

      it 'returns early without error' do
        expect { worker.perform(id) }.not_to raise_error
      end
    end
  end
end
