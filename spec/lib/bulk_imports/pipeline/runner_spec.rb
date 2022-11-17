# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline::Runner do
  let(:extractor) do
    Class.new do
      def initialize(options = {}); end

      def extract(context); end
    end
  end

  let(:transformer) do
    Class.new do
      def initialize(options = {}); end

      def transform(context, data); end
    end
  end

  let(:loader) do
    Class.new do
      def initialize(options = {}); end

      def load(context, data); end
    end
  end

  before do
    stub_const('BulkImports::Extractor', extractor)
    stub_const('BulkImports::Transformer', transformer)
    stub_const('BulkImports::Loader', loader)

    pipeline = Class.new do
      include BulkImports::Pipeline

      extractor BulkImports::Extractor
      transformer BulkImports::Transformer
      loader BulkImports::Loader
    end

    stub_const('BulkImports::MyPipeline', pipeline)
  end

  let_it_be_with_reload(:entity) { create(:bulk_import_entity) }

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker, extra: :data) }

  subject { BulkImports::MyPipeline.new(context) }

  shared_examples 'failed pipeline' do |exception_class, exception_message|
    it 'logs import failure' do
      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger).to receive(:error)
          .with(
            a_hash_including(
              'bulk_import_entity_id' => entity.id,
              'bulk_import_id' => entity.bulk_import_id,
              'bulk_import_entity_type' => entity.source_type,
              'source_full_path' => entity.source_full_path,
              'pipeline_step' => :extractor,
              'pipeline_class' => 'BulkImports::MyPipeline',
              'exception.class' => exception_class,
              'exception.message' => exception_message,
              'correlation_id' => anything,
              'class' => 'BulkImports::MyPipeline',
              'message' => "Pipeline failed",
              'importer' => 'gitlab_migration',
              'exception.backtrace' => anything,
              'source_version' => entity.bulk_import.source_version_info.to_s
            )
          )
      end

      expect { subject.run }
        .to change(entity.failures, :count).by(1)

      failure = entity.failures.first

      expect(failure).to be_present
      expect(failure.pipeline_class).to eq('BulkImports::MyPipeline')
      expect(failure.pipeline_step).to eq('extractor')
      expect(failure.exception_class).to eq(exception_class)
      expect(failure.exception_message).to eq(exception_message)
    end

    context 'when pipeline is marked to abort on failure' do
      before do
        BulkImports::MyPipeline.abort_on_failure!
      end

      it 'logs a warn message and marks entity and tracker as failed' do
        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger).to receive(:warn)
            .with(
              log_params(
                context,
                message: 'Aborting entity migration due to pipeline failure',
                pipeline_class: 'BulkImports::MyPipeline',
                importer: 'gitlab_migration'
              )
            )
        end

        subject.run

        expect(entity.failed?).to eq(true)
        expect(tracker.failed?).to eq(true)
      end
    end

    context 'when pipeline is not marked to abort on failure' do
      it 'does not mark entity as failed' do
        subject.run

        expect(tracker.failed?).to eq(true)
        expect(entity.failed?).to eq(false)
      end
    end
  end

  describe 'pipeline runner' do
    context 'when entity is not marked as failed' do
      it 'runs pipeline extractor, transformer, loader' do
        expect_next_instance_of(BulkImports::Extractor) do |extractor|
          expect(extractor)
            .to receive(:extract)
            .with(context)
            .and_return(extracted_data)
        end

        expect_next_instance_of(BulkImports::Transformer) do |transformer|
          expect(transformer)
            .to receive(:transform)
            .with(context, extracted_data.data.first)
            .and_return(extracted_data.data.first)
        end

        expect_next_instance_of(BulkImports::Loader) do |loader|
          expect(loader)
            .to receive(:load)
            .with(context, extracted_data.data.first)
        end

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger).to receive(:info)
            .with(
              log_params(
                context,
                message: 'Pipeline started',
                pipeline_class: 'BulkImports::MyPipeline'
              )
            )
          expect(logger).to receive(:info)
            .with(
              log_params(
                context,
                pipeline_class: 'BulkImports::MyPipeline',
                pipeline_step: :extractor,
                step_class: 'BulkImports::Extractor'
              )
            )
          expect(logger).to receive(:info)
            .with(
              log_params(
                context,
                pipeline_class: 'BulkImports::MyPipeline',
                pipeline_step: :transformer,
                step_class: 'BulkImports::Transformer'
              )
            )
          expect(logger).to receive(:info)
            .with(
              log_params(
                context,
                pipeline_class: 'BulkImports::MyPipeline',
                pipeline_step: :loader,
                step_class: 'BulkImports::Loader'
              )
            )
          expect(logger).to receive(:info)
            .with(
              log_params(
                context,
                pipeline_class: 'BulkImports::MyPipeline',
                pipeline_step: :after_run
              )
            )
          expect(logger).to receive(:info)
            .with(
              log_params(
                context,
                message: 'Pipeline finished',
                pipeline_class: 'BulkImports::MyPipeline'
              )
            )
        end

        subject.run
      end

      context 'when extracted data has multiple pages' do
        it 'updates tracker information and runs pipeline again' do
          first_page = extracted_data(has_next_page: true)
          last_page = extracted_data

          expect_next_instance_of(BulkImports::Extractor) do |extractor|
            expect(extractor)
              .to receive(:extract)
              .with(context)
              .and_return(first_page, last_page)
          end

          subject.run
        end
      end

      context 'when the exception BulkImports::NetworkError is raised' do
        before do
          allow_next_instance_of(BulkImports::Extractor) do |extractor|
            allow(extractor).to receive(:extract).with(context).and_raise(
              BulkImports::NetworkError.new(
                'Net::ReadTimeout',
                response: instance_double(HTTParty::Response, code: reponse_status_code, headers: {})
              )
            )
          end
        end

        context 'when exception is retriable' do
          let(:reponse_status_code) { 429 }

          it 'raises the exception BulkImports::RetryPipelineError' do
            expect { subject.run }.to raise_error(BulkImports::RetryPipelineError)
          end
        end

        context 'when exception is not retriable' do
          let(:reponse_status_code) { 503 }

          it_behaves_like 'failed pipeline', 'BulkImports::NetworkError', 'Net::ReadTimeout'
        end
      end

      context 'when a retriable BulkImports::NetworkError exception is raised while extracting the next page' do
        before do
          call_count = 0
          allow_next_instance_of(BulkImports::Extractor) do |extractor|
            allow(extractor).to receive(:extract).with(context).twice do
              if call_count.zero?
                call_count += 1
                extracted_data(has_next_page: true)
              else
                raise(
                  BulkImports::NetworkError.new(
                    response: instance_double(HTTParty::Response, code: 429, headers: {})
                  )
                )
              end
            end
          end
        end

        it 'raises the exception BulkImports::RetryPipelineError' do
          expect { subject.run }.to raise_error(BulkImports::RetryPipelineError)
        end
      end

      context 'when the exception StandardError is raised' do
        before do
          allow_next_instance_of(BulkImports::Extractor) do |extractor|
            allow(extractor).to receive(:extract).with(context).and_raise(StandardError, 'Error!')
          end
        end

        it_behaves_like 'failed pipeline', 'StandardError', 'Error!'
      end
    end

    context 'when entity is marked as failed' do
      it 'logs and returns without execution' do
        entity.fail_op!

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger).to receive(:warn)
            .with(
              log_params(
                context,
                message: 'Skipping pipeline due to failed entity',
                pipeline_class: 'BulkImports::MyPipeline'
              )
            )
        end

        subject.run
      end
    end

    def log_params(context, extra = {})
      {
        bulk_import_id: context.bulk_import_id,
        bulk_import_entity_id: context.entity.id,
        bulk_import_entity_type: context.entity.source_type,
        source_full_path: entity.source_full_path,
        source_version: context.entity.bulk_import.source_version_info.to_s,
        importer: 'gitlab_migration',
        context_extra: context.extra
      }.merge(extra)
    end

    def extracted_data(has_next_page: false)
      BulkImports::Pipeline::ExtractedData.new(
        data: { foo: :bar },
        page_info: {
          'has_next_page' => has_next_page,
          'next_page' => has_next_page ? 'cursor' : nil
        }
      )
    end
  end
end
