# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportStatus do
  let_it_be(:relation) { 'labels' }
  let_it_be(:import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: import, source_full_path: 'foo') }
  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }

  let(:response_double) do
    double(parsed_response: [{ 'relation' => 'labels', 'status' => status, 'error' => 'error!' }])
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
  end

  describe '#failed' do
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
  end

  describe '#error' do
    let(:status) { BulkImports::Export::FAILED }

    it 'returns error message' do
      expect(subject.error).to eq('error!')
    end

    context 'when something goes wrong during export status fetch' do
      it 'returns exception class as error' do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client).to receive(:get).and_raise(StandardError, 'Error!')
        end

        expect(subject.error).to eq('Error!')
      end
    end
  end
end
