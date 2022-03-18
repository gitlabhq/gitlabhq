# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportRequestWorker do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:version_url) { 'https://gitlab.example/api/v4/version' }

  let(:response_double) { double(code: 200, success?: true, parsed_response: {}) }
  let(:job_args) { [entity.id] }

  describe '#perform' do
    before do
      allow(Gitlab::HTTP)
        .to receive(:get)
        .with(version_url, anything)
        .and_return(double(code: 200, success?: true, parsed_response: { 'version' => Gitlab::VERSION }))
      allow(Gitlab::HTTP).to receive(:post).and_return(response_double)
    end

    shared_examples 'requests relations export for api resource' do
      include_examples 'an idempotent worker' do
        it 'requests relations export' do
          expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
            expect(client).to receive(:post).with(expected).twice
          end

          perform_multiple(job_args)
        end

        context 'when network error is raised' do
          it 'logs export failure and marks entity as failed' do
            expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
              expect(client).to receive(:post).and_raise(BulkImports::NetworkError, 'Export error').twice
            end

            expect(Gitlab::Import::Logger).to receive(:warn).with(
              bulk_import_entity_id: entity.id,
              pipeline_class: 'ExportRequestWorker',
              exception_class: 'BulkImports::NetworkError',
              exception_message: 'Export error',
              correlation_id_value: anything,
              bulk_import_id: bulk_import.id,
              bulk_import_entity_type: entity.source_type
            ).twice

            perform_multiple(job_args)

            failure = entity.failures.last

            expect(failure.pipeline_class).to eq('ExportRequestWorker')
            expect(failure.exception_message).to eq('Export error')
          end
        end
      end
    end

    context 'when entity is group' do
      let(:entity) { create(:bulk_import_entity, :group_entity, source_full_path: 'foo/bar', bulk_import: bulk_import) }
      let(:expected) { '/groups/foo%2Fbar/export_relations'}

      include_examples 'requests relations export for api resource'
    end

    context 'when entity is project' do
      let(:entity) { create(:bulk_import_entity, :project_entity, source_full_path: 'foo/bar', bulk_import: bulk_import) }
      let(:expected) { '/projects/foo%2Fbar/export_relations' }

      include_examples 'requests relations export for api resource'
    end
  end
end
