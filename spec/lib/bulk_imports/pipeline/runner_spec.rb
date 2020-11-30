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

      def transform(context); end
    end
  end

  let(:loader) do
    Class.new do
      def initialize(options = {}); end

      def load(context); end
    end
  end

  describe 'pipeline runner' do
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

    context 'when entity is not marked as failed' do
      let(:context) do
        instance_double(
          BulkImports::Pipeline::Context,
          entity: instance_double(BulkImports::Entity, id: 1, source_type: 'group', failed?: false)
        )
      end

      it 'runs pipeline extractor, transformer, loader' do
        entries = [{ foo: :bar }]

        expect_next_instance_of(BulkImports::Extractor) do |extractor|
          expect(extractor).to receive(:extract).with(context).and_return(entries)
        end

        expect_next_instance_of(BulkImports::Transformer) do |transformer|
          expect(transformer).to receive(:transform).with(context, entries.first).and_return(entries.first)
        end

        expect_next_instance_of(BulkImports::Loader) do |loader|
          expect(loader).to receive(:load).with(context, entries.first)
        end

        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger).to receive(:info)
            .with(
              message: 'Pipeline started',
              pipeline_class: 'BulkImports::MyPipeline',
              bulk_import_entity_id: 1,
              bulk_import_entity_type: 'group'
            )
          expect(logger).to receive(:info)
            .with(bulk_import_entity_id: 1, bulk_import_entity_type: 'group', extractor: 'BulkImports::Extractor')
          expect(logger).to receive(:info)
            .with(bulk_import_entity_id: 1, bulk_import_entity_type: 'group', transformer: 'BulkImports::Transformer')
          expect(logger).to receive(:info)
            .with(bulk_import_entity_id: 1, bulk_import_entity_type: 'group', loader: 'BulkImports::Loader')
        end

        BulkImports::MyPipeline.new.run(context)
      end

      context 'when exception is raised' do
        let(:entity) { create(:bulk_import_entity, :created) }
        let(:context) { BulkImports::Pipeline::Context.new(entity: entity) }

        before do
          allow_next_instance_of(BulkImports::Extractor) do |extractor|
            allow(extractor).to receive(:extract).with(context).and_raise(StandardError, 'Error!')
          end
        end

        it 'logs import failure' do
          BulkImports::MyPipeline.new.run(context)

          failure = entity.failures.first

          expect(failure).to be_present
          expect(failure.pipeline_class).to eq('BulkImports::MyPipeline')
          expect(failure.exception_class).to eq('StandardError')
          expect(failure.exception_message).to eq('Error!')
        end

        context 'when pipeline is marked to abort on failure' do
          before do
            BulkImports::MyPipeline.abort_on_failure!
          end

          it 'marks entity as failed' do
            BulkImports::MyPipeline.new.run(context)

            expect(entity.failed?).to eq(true)
          end

          it 'logs warn message' do
            expect_next_instance_of(Gitlab::Import::Logger) do |logger|
              expect(logger).to receive(:warn)
                .with(
                  message: 'Pipeline failed',
                  pipeline_class: 'BulkImports::MyPipeline',
                  bulk_import_entity_id: entity.id,
                  bulk_import_entity_type: entity.source_type
                )
            end

            BulkImports::MyPipeline.new.run(context)
          end
        end

        context 'when pipeline is not marked to abort on failure' do
          it 'marks entity as failed' do
            BulkImports::MyPipeline.new.run(context)

            expect(entity.failed?).to eq(false)
          end
        end
      end
    end

    context 'when entity is marked as failed' do
      let(:context) do
        instance_double(
          BulkImports::Pipeline::Context,
          entity: instance_double(BulkImports::Entity, id: 1, source_type: 'group', failed?: true)
        )
      end

      it 'logs and returns without execution' do
        expect_next_instance_of(Gitlab::Import::Logger) do |logger|
          expect(logger).to receive(:info)
            .with(
              message: 'Skipping due to failed pipeline status',
              pipeline_class: 'BulkImports::MyPipeline',
              bulk_import_entity_id: 1,
              bulk_import_entity_type: 'group'
            )
        end

        BulkImports::MyPipeline.new.run(context)
      end
    end
  end
end
