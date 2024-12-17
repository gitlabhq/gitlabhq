# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline::Runner, feature_category: :importers do
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

    allow_next_instance_of(BulkImports::ExportStatus) do |export_status|
      allow(export_status).to receive(:total_objects_count).and_return(1)
    end

    allow(tracker).to receive_message_chain(:pipeline_class, :relation).and_return('relation')
  end

  let_it_be(:bulk_import) { create(:bulk_import) }
  let_it_be(:configuration) { create(:bulk_import_configuration, bulk_import: bulk_import) }
  let_it_be_with_reload(:entity) { create(:bulk_import_entity, bulk_import: bulk_import) }

  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker, extra: :data) }

  subject { BulkImports::MyPipeline.new(context) }

  shared_examples 'failed pipeline' do |exception_class, exception_message|
    it 'logs import failure' do
      expect_next_instance_of(BulkImports::Logger) do |logger|
        expect(logger).to receive(:with_entity).with(context.entity).and_call_original
        expect(logger).to receive(:error)
          .with(
            a_hash_including(
              'bulk_import_id' => entity.bulk_import_id,
              'pipeline_step' => :extractor,
              'pipeline_class' => 'BulkImports::MyPipeline',
              'exception.class' => exception_class,
              'exception.message' => exception_message,
              'correlation_id' => anything,
              'class' => 'BulkImports::MyPipeline',
              'message' => 'An object of a pipeline failed to import',
              'exception.backtrace' => anything
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
        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:with_entity).with(context.entity).and_call_original
          expect(logger).to receive(:warn)
            .with(
              log_params(
                context,
                message: 'Aborting entity migration due to pipeline failure',
                pipeline_class: 'BulkImports::MyPipeline'
              )
            )
        end

        subject.run

        expect(entity.failed?).to eq(true)
        expect(tracker.failed?).to eq(true)
      end
    end

    context 'when pipeline is not marked to abort on failure' do
      it 'does not mark tracker and entity as failed' do
        subject.run

        expect(tracker.failed?).to eq(false)
        expect(entity.failed?).to eq(false)
      end
    end

    context 'when failure happens during loader' do
      before do
        allow(tracker).to receive(:pipeline_class).and_return(BulkImports::MyPipeline)
        allow(BulkImports::MyPipeline).to receive(:relation).and_return(relation)

        allow_next_instance_of(BulkImports::Extractor) do |extractor|
          allow(extractor).to receive(:extract).with(context).and_return(extracted_data)
        end

        allow_next_instance_of(BulkImports::Transformer) do |transformer|
          allow(transformer).to receive(:transform).with(context, extracted_data.data.first).and_return(entry)
        end

        allow_next_instance_of(BulkImports::Loader) do |loader|
          allow(loader).to receive(:load).with(context, entry).and_raise(StandardError, 'Error!')
        end
      end

      context 'when entry has title' do
        let(:relation) { 'issues' }
        let(:entry) { Issue.new(iid: 1, title: 'hello world') }

        it 'creates failure record with source url and title' do
          subject.run

          failure = entity.failures.first
          expected_source_url = File.join(configuration.url, 'groups', entity.source_full_path, '-', 'issues', '1')

          expect(failure).to be_present
          expect(failure.source_url).to eq(expected_source_url)
          expect(failure.source_title).to eq('hello world')
        end
      end

      context 'when entry has name' do
        let(:relation) { 'boards' }
        let(:entry) { Board.new(name: 'hello world') }

        it 'creates failure record with name' do
          subject.run

          failure = entity.failures.first

          expect(failure).to be_present
          expect(failure.source_url).to be_nil
          expect(failure.source_title).to eq('hello world')
        end
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

        expect(subject).to receive(:on_finish)
        expect(context.bulk_import).to receive(:touch)
        expect(context.entity).to receive(:touch)
        expect(subject).to receive(:delete_existing_records).once

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:with_entity).with(context.entity).and_call_original
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
                pipeline_step: :on_finish
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

      context 'when the pipeline is batched' do
        let(:tracker) { create(:bulk_import_tracker, :batched, entity: entity) }

        before do
          allow_next_instance_of(BulkImports::Extractor) do |extractor|
            allow(extractor).to receive(:extract).and_return(extracted_data)
          end
        end

        it 'calls after_run' do
          expect(subject).to receive(:after_run)

          subject.run
        end

        it 'does not call on_finish' do
          expect(subject).not_to receive(:on_finish)

          subject.run
        end
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

      [Gitlab::Import::SourceUserMapper::FailedToObtainLockError,
        Gitlab::Import::SourceUserMapper::DuplicatedUserError].each do |exception_class|
        context "when #{exception_class} is raised" do
          it 'raises the exception BulkImports::RetryPipelineError' do
            allow_next_instance_of(BulkImports::Extractor) do |extractor|
              allow(extractor)
                .to receive(:extract)
                .with(context)
                .and_return(extracted_data)
            end

            allow_next_instance_of(BulkImports::Transformer) do |transformer|
              allow(transformer)
                .to receive(:transform)
                .and_raise(exception_class)
            end

            expect { subject.run }.to raise_error(BulkImports::RetryPipelineError)
          end
        end
      end

      context 'when the exception BulkImports::NetworkError is raised' do
        before do
          allow_next_instance_of(BulkImports::Extractor) do |extractor|
            allow(extractor).to receive(:extract).with(context).and_raise(
              BulkImports::NetworkError.new(
                'Net::ReadTimeout',
                response: instance_double(HTTParty::Response, code: response_status_code, headers: {})
              )
            )
          end
        end

        context 'when exception is retriable' do
          let(:response_status_code) { 429 }

          it 'raises the exception BulkImports::RetryPipelineError' do
            expect { subject.run }.to raise_error(BulkImports::RetryPipelineError)
          end
        end

        context 'when exception is not retriable' do
          let(:response_status_code) { 505 }

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

      it 'saves entry in cache for de-duplication' do
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

        expect_next_instance_of(BulkImports::MyPipeline) do |klass|
          expect(klass).to receive(:save_processed_entry).with(extracted_data.data.first, anything)
        end

        subject.run
      end
    end

    context 'when the entry is already processed' do
      before do
        allow(subject).to receive(:already_processed?).and_return(true)
      end

      it 'runs pipeline extractor, but not transformer or loader' do
        expect_next_instance_of(BulkImports::Extractor) do |extractor|
          expect(extractor)
            .to receive(:extract)
            .with(context)
            .and_return(extracted_data)
        end

        expect(BulkImports::Transformer).not_to receive(:new)
        expect(BulkImports::Loader).not_to receive(:new)

        subject.run
      end
    end

    context 'when entity is marked as failed' do
      it 'logs and returns without execution' do
        entity.fail_op!

        expect_next_instance_of(BulkImports::Logger) do |logger|
          expect(logger).to receive(:with_entity).with(context.entity).and_call_original
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

    describe 'object counting' do
      it 'increments object counters' do
        allow_next_instance_of(BulkImports::Extractor) do |extractor|
          allow(extractor).to receive(:extract).with(context).and_return(extracted_data)
        end

        allow_next_instance_of(BulkImports::Transformer) do |transformer|
          allow(transformer)
            .to receive(:transform)
            .with(context, extracted_data.data.first)
            .and_return(extracted_data.data.first)
        end

        allow_next_instance_of(BulkImports::Loader) do |loader|
          expect(loader).to receive(:load).with(context, extracted_data.data.first)
        end

        expect(BulkImports::ObjectCounter).to receive(:set).with(tracker, :source, 1)
        expect(BulkImports::ObjectCounter).to receive(:increment).with(tracker, :fetched)
        expect(BulkImports::ObjectCounter).to receive(:increment).with(tracker, :imported)

        subject.run

        expect(tracker.source_objects_count).to eq(1)
        expect(tracker.fetched_objects_count).to eq(1)
        expect(tracker.imported_objects_count).to eq(1)
      end
    end

    describe 'delete partial imported records' do
      it 'calls delete_existing_records method for the first non processed entry' do
        allow_next_instance_of(BulkImports::Extractor) do |extractor|
          allow(extractor).to receive(:extract).with(context)
            .and_return(BulkImports::Pipeline::ExtractedData.new(data: [{ id: 1 }, { id: 2 }, { id: 3 }]))
        end

        allow(subject).to receive(:already_processed?).and_return(true, false, false)

        expect(subject).to receive(:delete_existing_records).with({ id: 2 }).once

        subject.run
      end
    end

    def log_params(context, extra = {})
      {
        bulk_import_id: context.bulk_import_id,
        context_extra: context.extra
      }.merge(extra)
    end

    def extracted_data(has_next_page: false)
      BulkImports::Pipeline::ExtractedData.new(
        data: {
          'foo' => 'bar',
          'title' => 'hello world',
          'iid' => 1
        },
        page_info: {
          'has_next_page' => has_next_page,
          'next_page' => has_next_page ? 'cursor' : nil
        }
      )
    end
  end
end
