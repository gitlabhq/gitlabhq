# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::ExportRequestWorker, feature_category: :importers do
  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
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
      it_behaves_like 'an idempotent worker' do
        it 'requests relations export & schedules entity worker' do
          expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
            expect(client).to receive(:post).with(expected).twice
          end

          expect(BulkImports::EntityWorker).to receive(:perform_async).twice

          perform_multiple(job_args)
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

            it 'logs the exception as a warning & requests relations export using full path url' do
              allow(BulkImports::EntityWorker).to receive(:perform_async)

              expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
                expect(client).to receive(:post).with(full_path_url).twice
              end

              entity.update!(source_xid: nil)

              expect_next_instance_of(BulkImports::Logger) do |logger|
                expect(logger).to receive(:with_entity).with(entity).and_call_original

                expect(logger).to receive(:warn).with(
                  a_hash_including(
                    'exception.backtrace' => anything,
                    'exception.class' => 'NoMethodError',
                    'exception.message' => /^undefined method `model_id' for nil/,
                    'message' => 'Failed to fetch source entity id'
                  )
                ).twice
              end

              perform_multiple(job_args)

              expect(entity.source_xid).to be_nil
            end
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

    context 'when source supports batched migration' do
      let_it_be(:bulk_import) { create(:bulk_import, source_version: BulkImport.min_gl_version_for_migration_in_batches) }
      let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import) }
      let_it_be(:entity) { create(:bulk_import_entity, :project_entity, source_full_path: 'foo/bar', bulk_import: bulk_import) }

      it 'requests relations export & schedules entity worker' do
        expected_url = "/projects/#{entity.source_xid}/export_relations?batched=true"

        expect_next_instance_of(BulkImports::Clients::HTTP) do |client|
          expect(client).to receive(:post).with(expected_url)
        end

        described_class.new.perform(entity.id)
      end
    end
  end

  describe '#sidekiq_retries_exhausted' do
    it 'logs export failure and marks entity as failed' do
      entity = create(:bulk_import_entity, bulk_import: bulk_import)
      error = 'Exhausted error!'

      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:with_entity).with(entity).and_call_original

        expect(logger)
          .to receive(:error)
          .with(hash_including('message' => "Request to export #{entity.source_type} failed"))
      end

      described_class
        .sidekiq_retries_exhausted_block
        .call({ 'args' => [entity.id] }, StandardError.new(error))

      expect(entity.reload.failed?).to eq(true)
      expect(entity.failures.last.exception_message).to eq(error)
    end
  end
end
