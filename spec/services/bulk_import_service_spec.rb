# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImportService do
  let(:user) { create(:user) }
  let(:credentials) { { url: 'http://gitlab.example', access_token: 'token' } }
  let(:params) do
    [
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group1',
        destination_name: 'destination group 1',
        destination_namespace: 'full/path/to/destination1'
      },
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group2',
        destination_name: 'destination group 2',
        destination_namespace: 'full/path/to/destination2'
      },
      {
        source_type: 'project_entity',
        source_full_path: 'full/path/to/project1',
        destination_name: 'destination project 1',
        destination_namespace: 'full/path/to/destination1'
      }
    ]
  end

  subject { described_class.new(user, params, credentials) }

  describe '#execute' do
    it 'creates bulk import' do
      expect { subject.execute }.to change { BulkImport.count }.by(1)
    end

    it 'creates bulk import entities' do
      expect { subject.execute }.to change { BulkImports::Entity.count }.by(3)
    end

    it 'creates bulk import configuration' do
      expect { subject.execute }.to change { BulkImports::Configuration.count }.by(1)
    end

    it 'enqueues BulkImportWorker' do
      expect(BulkImportWorker).to receive(:perform_async)

      subject.execute
    end

    it 'returns success ServiceResponse' do
      result = subject.execute

      expect(result).to be_a(ServiceResponse)
      expect(result).to be_success
    end

    it 'returns ServiceResponse with error if validation fails' do
      params[0][:source_full_path] = nil

      result = subject.execute

      expect(result).to be_a(ServiceResponse)
      expect(result).to be_error
      expect(result.message).to eq("Validation failed: Source full path can't be blank")
    end
  end
end
