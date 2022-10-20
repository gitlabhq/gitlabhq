# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportStatus do
  let_it_be(:relation) { 'labels' }
  let_it_be(:import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import, source_full_path: 'foo') }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }

  let(:response_double) do
    instance_double(HTTParty::Response,
      parsed_response: [{ 'relation' => 'labels', 'status' => status, 'error' => 'error!' }]
    )
  end

  subject { described_class.new(tracker, relation) }

  before do
    allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
      allow(client).to receive(:get).and_return(response_double)
    end
  end

  describe '#started?' do
    context 'when export status is started' do
      let(:status) { BulkImports::Export::STARTED }

      it 'returns true' do
        expect(subject.started?).to eq(true)
      end
    end

    context 'when export status is not started' do
      let(:status) { BulkImports::Export::FAILED }

      it 'returns false' do
        expect(subject.started?).to eq(false)
      end
    end

    context 'when export status is not present' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it 'returns false' do
        expect(subject.started?).to eq(false)
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
        expect(subject.started?).to eq(false)
      end
    end
  end

  describe '#failed?' do
    context 'when export status is failed' do
      let(:status) { BulkImports::Export::FAILED }

      it 'returns true' do
        expect(subject.failed?).to eq(true)
      end
    end

    context 'when export status is not failed' do
      let(:status) { BulkImports::Export::STARTED }

      it 'returns false' do
        expect(subject.failed?).to eq(false)
      end
    end

    context 'when export status is not present' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it 'returns false' do
        expect(subject.started?).to eq(false)
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
        expect(subject.started?).to eq(false)
      end
    end
  end

  describe '#empty?' do
    context 'when export status is present' do
      let(:status) { 'any status' }

      it { expect(subject.empty?).to eq(false) }
    end

    context 'when export status is not present' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: [])
      end

      it 'returns true' do
        expect(subject.empty?).to eq(true)
      end
    end

    context 'when export status is empty' do
      let(:response_double) do
        instance_double(HTTParty::Response, parsed_response: nil)
      end

      it 'returns true' do
        expect(subject.empty?).to eq(true)
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
        expect(subject.started?).to eq(false)
      end
    end
  end

  describe '#error' do
    let(:status) { BulkImports::Export::FAILED }

    it 'returns error message' do
      expect(subject.error).to eq('error!')
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

        expect { subject.failed? }.to raise_error(BulkImports::RetryPipelineError)
      end

      context 'when error is not retriable' do
        it 'returns exception class as error' do
          expect(subject.error).to eq('Error!')
          expect(subject.failed?).to eq(true)
        end
      end

      context 'when error raised is not a network error' do
        it 'returns exception class as error' do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:get).once.and_raise(StandardError, 'Standard Error!')
          end

          expect(subject.error).to eq('Standard Error!')
          expect(subject.failed?).to eq(true)
        end
      end
    end
  end
end
