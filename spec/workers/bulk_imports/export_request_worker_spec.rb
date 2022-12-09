# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportRequestWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
  let(:job_args) { [entity.id] }
  let(:response_headers) { { 'Content-Type' => 'application/json' } }
  let(:request_query) { { page: 1, per_page: 30, private_token: 'token' } }
  let(:personal_access_tokens_response) do
    {
      scopes: %w[api read_repository]
    }
  end

  let_it_be(:source_version) do
    Gitlab::VersionInfo.new(::BulkImport::MIN_MAJOR_VERSION,
                            ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT)
  end

  describe '#perform' do
    before do
      stub_request(:get, 'https://gitlab.example/api/v4/version').with(query: request_query)
        .to_return(status: 200, body: { 'version' => Gitlab::VERSION }.to_json, headers: response_headers)
      stub_request(:get, 'https://gitlab.example/api/v4/personal_access_tokens/self').with(query: request_query)
        .to_return(status: 200, body: personal_access_tokens_response.to_json, headers: response_headers)
    end

    context 'when scope validation fails' do
      let(:personal_access_tokens_response) { { scopes: ['read_user'] } }

      it 'creates a failure record' do
        expect(BulkImports::Failure)
          .to receive(:create)
          .with(
            a_hash_including(
              bulk_import_entity_id: entity.id,
              pipeline_class: 'ExportRequestWorker',
              exception_class: 'BulkImports::Error',
              exception_message: 'Migration aborted as the provided personal access token is no longer valid.',
              correlation_id_value: anything
            )
          ).twice

        perform_multiple(job_args)
      end
    end

    shared_examples 'requests relations export for api resource' do
      it_behaves_like 'an idempotent worker' do
        it 'requests relations export & schedules entity worker' do
          expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
            expect(client).to receive(:post).with(expected).twice
          end

          expect(BulkImports::EntityWorker).to receive(:perform_async).twice

          perform_multiple(job_args)
        end

        context 'when network error is raised' do
          let(:exception) { BulkImports::NetworkError.new('Export error') }

          before do
            allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
              allow(client).to receive(:post).and_raise(exception).twice
            end
          end

          context 'when error is retriable' do
            it 'logs retry request and reenqueues' do
              allow(exception).to receive(:retriable?).twice.and_return(true)

              expect_next_instance_of(Gitlab::Import::Logger) do |logger|
                expect(logger).to receive(:error).with(
                  a_hash_including(
                    'bulk_import_entity_id' => entity.id,
                    'bulk_import_id' => entity.bulk_import_id,
                    'bulk_import_entity_type' => entity.source_type,
                    'source_full_path' => entity.source_full_path,
                    'exception.backtrace' => anything,
                    'exception.class' => 'BulkImports::NetworkError',
                    'exception.message' => 'Export error',
                    'message' => 'Retrying export request',
                    'importer' => 'gitlab_migration',
                    'source_version' => entity.bulk_import.source_version_info.to_s
                  )
                ).twice
              end

              expect(described_class).to receive(:perform_in).twice.with(2.seconds, entity.id)

              perform_multiple(job_args)
            end
          end

          context 'when error is not retriable' do
            it 'logs export failure and marks entity as failed' do
              allow(exception).to receive(:retriable?).twice.and_return(false)

              expect_next_instance_of(Gitlab::Import::Logger) do |logger|
                expect(logger).to receive(:error).with(
                  a_hash_including(
                    'bulk_import_entity_id' => entity.id,
                    'bulk_import_id' => entity.bulk_import_id,
                    'bulk_import_entity_type' => entity.source_type,
                    'source_full_path' => entity.source_full_path,
                    'exception.backtrace' => anything,
                    'exception.class' => 'BulkImports::NetworkError',
                    'exception.message' => 'Export error',
                    'message' => "Request to export #{entity.source_type} failed",
                    'importer' => 'gitlab_migration',
                    'source_version' => entity.bulk_import.source_version_info.to_s
                  )
                ).twice
              end

              perform_multiple(job_args)

              failure = entity.failures.last

              expect(failure.pipeline_class).to eq('ExportRequestWorker')
              expect(failure.exception_message).to eq('Export error')
            end
          end
        end

        context 'when source id is nil' do
          let(:entity_source_id) { 'gid://gitlab/Model/1234567' }

          before do
            graphql_client = instance_double(BulkImports::Clients::Graphql)
            response = double(original_hash: { 'data' => { entity.entity_type => { 'id' => entity_source_id } } })

            allow(BulkImports::Clients::Graphql).to receive(:new).and_return(graphql_client)
            allow(graphql_client).to receive(:parse)
            allow(graphql_client).to receive(:execute).and_return(response)
          end

          it 'updates entity source id & requests export using source id' do
            expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
              expect(client)
                .to receive(:post)
                .with("/#{entity.pluralized_name}/1234567/export_relations")
                .twice
            end

            entity.update!(source_xid: nil)

            perform_multiple(job_args)

            expect(entity.reload.source_xid).to eq(1234567)
          end

          context 'when something goes wrong during source id fetch' do
            let(:entity_source_id) { 'invalid' }

            it 'logs the error & requests relations export using full path url' do
              allow(BulkImports::EntityWorker).to receive(:perform_async)

              expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
                expect(client).to receive(:post).with(full_path_url).twice
              end

              entity.update!(source_xid: nil)

              expect_next_instance_of(Gitlab::Import::Logger) do |logger|
                expect(logger).to receive(:error).with(
                  a_hash_including(
                    'bulk_import_entity_id' => entity.id,
                    'bulk_import_id' => entity.bulk_import_id,
                    'bulk_import_entity_type' => entity.source_type,
                    'source_full_path' => entity.source_full_path,
                    'exception.backtrace' => anything,
                    'exception.class' => 'NoMethodError',
                    'exception.message' => "undefined method `model_id' for nil:NilClass",
                    'message' => 'Failed to fetch source entity id',
                    'importer' => 'gitlab_migration',
                    'source_version' => entity.bulk_import.source_version_info.to_s
                  )
                ).twice
              end

              perform_multiple(job_args)

              expect(entity.source_xid).to be_nil
            end
          end
        end
      end

      context 'when entity is group' do
        let(:entity) { create(:bulk_import_entity, :group_entity, source_full_path: 'foo/bar', bulk_import: bulk_import) }
        let(:expected) { "/groups/#{entity.source_xid}/export_relations" }
        let(:full_path_url) { '/groups/foo%2Fbar/export_relations' }

        it_behaves_like 'requests relations export for api resource'
      end

      context 'when entity is project' do
        let(:entity) { create(:bulk_import_entity, :project_entity, source_full_path: 'foo/bar', bulk_import: bulk_import) }
        let(:expected) { "/projects/#{entity.source_xid}/export_relations" }
        let(:full_path_url) { '/projects/foo%2Fbar/export_relations' }

        it_behaves_like 'requests relations export for api resource'
      end
    end
  end
end
