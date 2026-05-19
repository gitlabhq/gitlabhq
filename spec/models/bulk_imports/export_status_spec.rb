# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportStatus, :clean_gitlab_redis_shared_state, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:relation) { 'labels' }
  let_it_be(:import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import, source_full_path: 'foo') }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }

  let(:batched) { false }
  let(:batches) { [] }
  let(:response_double) do
    instance_double(HTTParty::Response,
      parsed_response: [
        {
          'relation' => 'labels',
          'status' => status,
          'error' => 'error!',
          'batched' => batched,
          'batches' => batches,
          'batches_count' => 1,
          'total_objects_count' => 1
        }
      ]
    )
  end

  subject(:export_status) { described_class.new(tracker, relation) }

  before do
    allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
      allow(client).to receive(:get).and_return(response_double)
    end
  end

  describe '#in_progress?' do
    subject(:in_progress?) { export_status.in_progress? }

    where(:status, :result) do
      BulkImports::Export::PENDING  | true
      BulkImports::Export::STARTED  | true
      BulkImports::Export::FINISHED | false
      BulkImports::Export::FAILED   | false
    end

    with_them do
      it { is_expected.to eq(result) }
    end

    context 'when export status is not present' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it { is_expected.to be(false) }
    end

    context 'when something goes wrong during export status fetch' do
      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client).to receive(:get).and_raise(
            BulkImports::NetworkError.new("Unsuccessful response", response: nil)
          )
        end
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#failed?' do
    context 'when export status is failed' do
      let(:status) { BulkImports::Export::FAILED }

      it 'returns true' do
        expect(export_status.failed?).to eq(true)
      end
    end

    context 'when export status is not failed' do
      let(:status) { BulkImports::Export::STARTED }

      it 'returns false' do
        expect(export_status.failed?).to eq(false)
      end
    end

    context 'when export status is not present' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it 'returns false' do
        expect(export_status.failed?).to eq(false)
      end
    end

    context 'when something goes wrong during export status fetch' do
      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client).to receive(:get).and_raise(
            BulkImports::NetworkError.new("Unsuccessful response", response: nil)
          )
        end
      end

      it 'returns true' do
        expect(export_status.failed?).to eq(true)
      end
    end
  end

  describe '#waiting_on_export?' do
    context 'when export status is present' do
      let(:status) { 'any status' }

      it { expect(export_status.waiting_on_export?).to eq(false) }
    end

    context 'when export status is not present' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it 'returns true' do
        expect(export_status.waiting_on_export?).to eq(true)
      end
    end

    context 'when export status is empty' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: nil)
      end

      it 'returns true' do
        expect(export_status.waiting_on_export?).to eq(true)
      end
    end

    context 'when something goes wrong during export status fetch' do
      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client).to receive(:get).and_raise(
            BulkImports::NetworkError.new("Unsuccessful response", response: nil)
          )
        end
      end

      it 'returns false' do
        expect(export_status.waiting_on_export?).to eq(false)
      end
    end
  end

  describe '#error' do
    let(:status) { BulkImports::Export::FAILED }

    it 'returns error message' do
      expect(export_status.error).to eq('error!')
    end

    context 'when something goes wrong during export status fetch' do
      let(:exception) { BulkImports::NetworkError.new('Error!') }

      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client).to receive(:get).once.and_raise(exception)
        end
      end

      it 'raises RetryPipelineError' do
        allow(exception).to receive(:retriable?).with(tracker).and_return(true)

        expect { export_status.failed? }.to raise_error(BulkImports::RetryPipelineError)
      end

      context 'when error is not retriable' do
        it 'returns exception class as error' do
          expect(export_status.error).to eq('Error!')
          expect(export_status.failed?).to eq(true)
        end
      end

      context 'when error raised is not a network error' do
        it 'returns exception class as error' do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:get).once.and_raise(StandardError, 'Standard Error!')
          end

          expect(export_status.error).to eq('Standard Error!')
          expect(export_status.failed?).to eq(true)
        end
      end
    end
  end

  describe 'batching information' do
    let(:status) { BulkImports::Export::FINISHED }

    describe '#batched?' do
      context 'when export is batched' do
        let(:batched) { true }

        it 'returns true' do
          expect(export_status.batched?).to eq(true)
        end
      end

      context 'when export is not batched' do
        it 'returns false' do
          expect(export_status.batched?).to eq(false)
        end
      end

      context 'when export batch information is missing' do
        let(:response_double) do
          instance_double(HTTParty::Response, parsed_response: [{ 'relation' => 'labels', 'status' => status }])
        end

        it 'returns false' do
          expect(export_status.batched?).to eq(false)
        end
      end
    end

    describe '#batches_count' do
      context 'when batches count is present' do
        it 'returns batches count' do
          expect(export_status.batches_count).to eq(1)
        end
      end

      context 'when batches count is missing' do
        let(:response_double) do
          instance_double(HTTParty::Response, parsed_response: [{ 'relation' => 'labels', 'status' => status }])
        end

        it 'returns 0' do
          expect(export_status.batches_count).to eq(0)
        end
      end
    end

    describe '#all_batch_numbers' do
      context 'when batches count is present' do
        let(:response_double) do
          instance_double(
            HTTParty::Response,
            parsed_response: [{ 'relation' => 'labels', 'status' => status, 'batches_count' => 5 }])
        end

        it 'an array from 1 to batches_count' do
          expect(export_status.all_batch_numbers).to eq([1, 2, 3, 4, 5])
        end
      end

      context 'when batches count is missing' do
        let(:response_double) do
          instance_double(HTTParty::Response, parsed_response: [{ 'relation' => 'labels', 'status' => status }])
        end

        it 'returns an empty array' do
          expect(export_status.all_batch_numbers).to be_empty
        end
      end
    end

    describe '#batch_failed?' do
      context 'when export is batched' do
        let(:batched) { true }
        let(:statuses) { BulkImports::ExportBatch::STATE_VALUES }
        let(:batches) do
          [
            { 'relation' => 'labels', 'status' => statuses[:created], 'batch_number' => 1 },
            { 'relation' => 'labels', 'status' => statuses[:finished], 'batch_number' => 2 },
            { 'relation' => 'labels', 'status' => statuses[:started], 'batch_number' => 3 },
            { 'relation' => 'labels', 'status' => statuses[:failed], 'batch_number' => 4 }
          ]
        end

        it 'returns true for batches with failed status' do
          expect(export_status.batch_failed?(4)).to be(true)
        end

        it 'returns false for batches without failed status', :aggregate_failures do
          expect(export_status.batch_failed?(1)).to be(false)
          expect(export_status.batch_failed?(2)).to be(false)
          expect(export_status.batch_failed?(3)).to be(false)
        end

        it 'returns false when batch does not exist' do
          expect(export_status.batch_failed?(5)).to be(false)
        end
      end

      context 'when batch number is less than 1' do
        it 'raises error' do
          expect { export_status.batch_failed?(0) }.to raise_error(
            ArgumentError, 'Batch number (0) must be >= 1'
          )
        end
      end

      context 'when export is not batched' do
        it 'returns false' do
          expect(export_status.batch_failed?(1)).to be(false)
        end
      end
    end

    describe '#batch_error' do
      context 'when export is batched' do
        let(:batched) { true }
        let(:statuses) { BulkImports::ExportBatch::STATE_VALUES }
        let(:batches) do
          [
            { 'relation' => 'labels', 'status' => statuses[:failed], 'batch_number' => 1, 'error' => 'Error' }
          ]
        end

        it 'returns batch error' do
          expect(export_status.batch_error(1)).to be('Error')
        end

        it 'returns nil when batch does not exist' do
          expect(export_status.batch_error(2)).to be_nil
        end
      end

      context 'when batch number is less than 1' do
        it 'raises error' do
          expect { export_status.batch_failed?(0) }.to raise_error(ArgumentError)
        end
      end

      context 'when export is not batched' do
        it 'returns nil' do
          expect(export_status.batch_error(1)).to be_nil
        end
      end
    end
  end

  describe 'caching' do
    let(:cached_status) do
      export_status.send(:status)
      export_status.send(:status_from_cache)
    end

    shared_examples 'does not result in a cached status' do
      specify do
        expect(cached_status).to be_nil
      end
    end

    shared_examples 'results in a cached status' do
      specify do
        expect(cached_status).to include('status' => status)
      end

      context 'when something goes wrong during export status fetch' do
        before do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:get).and_raise(
              BulkImports::NetworkError.new("Unsuccessful response", response: nil)
            )
          end
        end

        include_examples 'does not result in a cached status'
      end
    end

    context 'when export status is started' do
      let(:status) { BulkImports::Export::STARTED }

      it_behaves_like 'does not result in a cached status'
    end

    context 'when export status is failed' do
      let(:status) { BulkImports::Export::FAILED }

      it_behaves_like 'results in a cached status'
    end

    context 'when export status is finished' do
      let(:status) { BulkImports::Export::FINISHED }

      it_behaves_like 'results in a cached status'
    end

    context 'when export status is not present' do
      let(:status) { nil }

      it_behaves_like 'does not result in a cached status'
    end

    context 'when the cache is empty' do
      let(:status) { BulkImports::Export::FAILED }

      it 'fetches the status from the remote' do
        expect(export_status).to receive(:status_from_remote).and_call_original
        expect(export_status.send(:status)).to include('status' => status)
      end
    end

    context 'when the cache is not empty' do
      let(:status) { BulkImports::Export::FAILED }

      before do
        Gitlab::Cache::Import::Caching.write(
          described_class.new(tracker, 'labels').send(:cache_key),
          { 'status' => 'mock status' }.to_json
        )
      end

      it 'does not fetch the status from the remote' do
        expect(export_status).not_to receive(:status_from_remote)
        expect(export_status.send(:status)).to eq({ 'status' => 'mock status' })
      end

      context 'with a different entity' do
        before do
          tracker.entity = create(:bulk_import_entity, bulk_import: import, source_full_path: 'foo')
        end

        it 'fetches the status from the remote' do
          expect(export_status).to receive(:status_from_remote).and_call_original
          expect(export_status.send(:status)).to include('status' => status)
        end
      end

      context 'with a different relation' do
        let_it_be(:relation) { 'merge_requests' }

        let(:response_double) do
          instance_double(HTTParty::Response, parsed_response: [
            { 'relation' => 'labels', 'status' => status },
            { 'relation' => 'merge_requests', 'status' => status }
          ])
        end

        it 'fetches the status from the remote' do
          expect(export_status).to receive(:status_from_remote).and_call_original
          expect(export_status.send(:status)).to include('status' => status)
        end
      end
    end
  end

  describe '#total_objects_count' do
    context 'when status is present' do
      let(:status) { BulkImports::Export::FINISHED }

      it 'returns total objects count' do
        expect(export_status.total_objects_count).to eq(1)
      end
    end

    context 'when status is not present due to an error' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it 'returns 0' do
        expect(export_status.total_objects_count).to eq(0)
      end
    end
  end
end
