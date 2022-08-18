# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::CreateService do
  let(:user) { create(:user) }
  let(:credentials) { { url: 'http://gitlab.example', access_token: 'token' } }
  let(:params) do
    [
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group1',
        destination_slug: 'destination group 1',
        destination_namespace: 'full/path/to/destination1'
      },
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group2',
        destination_slug: 'destination group 2',
        destination_namespace: 'full/path/to/destination2'
      },
      {
        source_type: 'project_entity',
        source_full_path: 'full/path/to/project1',
        destination_slug: 'destination project 1',
        destination_namespace: 'full/path/to/destination1'
      }
    ]
  end

  subject { described_class.new(user, params, credentials) }

  describe '#execute' do
    let_it_be(:source_version) do
      Gitlab::VersionInfo.new(::BulkImport::MIN_MAJOR_VERSION,
                              ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT)
    end

    before do
      allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
        allow(instance).to receive(:instance_version).and_return(source_version)
      end
    end

    it 'creates bulk import' do
      expect { subject.execute }.to change { BulkImport.count }.by(1)

      last_bulk_import = BulkImport.last

      expect(last_bulk_import.user).to eq(user)
      expect(last_bulk_import.source_version).to eq(source_version.to_s)
      expect(last_bulk_import.user).to eq(user)
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
