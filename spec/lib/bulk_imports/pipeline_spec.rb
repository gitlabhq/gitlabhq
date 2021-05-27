# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline do
  let(:context) { instance_double(BulkImports::Pipeline::Context, tracker: nil) }

  before do
    stub_const('BulkImports::Extractor', Class.new)
    stub_const('BulkImports::Transformer', Class.new)
    stub_const('BulkImports::Loader', Class.new)

    klass = Class.new do
      include BulkImports::Pipeline

      abort_on_failure!

      extractor BulkImports::Extractor, foo: :bar
      transformer BulkImports::Transformer, foo: :bar
      loader BulkImports::Loader, foo: :bar
    end

    stub_const('BulkImports::MyPipeline', klass)
  end

  describe 'pipeline attributes' do
    describe 'getters' do
      it 'retrieves class attributes' do
        expect(BulkImports::MyPipeline.get_extractor).to eq({ klass: BulkImports::Extractor, options: { foo: :bar } })
        expect(BulkImports::MyPipeline.transformers).to contain_exactly({ klass: BulkImports::Transformer, options: { foo: :bar } })
        expect(BulkImports::MyPipeline.get_loader).to eq({ klass: BulkImports::Loader, options: { foo: :bar } })
        expect(BulkImports::MyPipeline.abort_on_failure?).to eq(true)
      end

      context 'when extractor and loader are defined within the pipeline' do
        before do
          klass = Class.new do
            include BulkImports::Pipeline

            def extract; end

            def load; end
          end

          stub_const('BulkImports::AnotherPipeline', klass)
        end

        it 'returns itself when retrieving extractor & loader' do
          pipeline = BulkImports::AnotherPipeline.new(context)

          expect(pipeline.send(:extractor)).to eq(pipeline)
          expect(pipeline.send(:loader)).to eq(pipeline)
        end
      end
    end

    describe 'setters' do
      it 'sets class attributes' do
        klass = Class.new
        options = { test: :test }

        BulkImports::MyPipeline.extractor(klass, options)
        BulkImports::MyPipeline.transformer(klass, options)
        BulkImports::MyPipeline.loader(klass, options)
        BulkImports::MyPipeline.abort_on_failure!
        BulkImports::MyPipeline.ndjson_pipeline!

        expect(BulkImports::MyPipeline.get_extractor).to eq({ klass: klass, options: options })

        expect(BulkImports::MyPipeline.transformers)
          .to contain_exactly(
            { klass: BulkImports::Transformer, options: { foo: :bar } },
            { klass: klass, options: options })

        expect(BulkImports::MyPipeline.get_loader).to eq({ klass: klass, options: options })

        expect(BulkImports::MyPipeline.abort_on_failure?).to eq(true)
        expect(BulkImports::MyPipeline.ndjson_pipeline?).to eq(true)
      end
    end
  end

  describe '#instantiate' do
    context 'when options are present' do
      it 'instantiates new object with options' do
        expect(BulkImports::Extractor).to receive(:new).with(foo: :bar)
        expect(BulkImports::Transformer).to receive(:new).with(foo: :bar)
        expect(BulkImports::Loader).to receive(:new).with(foo: :bar)

        pipeline = BulkImports::MyPipeline.new(context)

        pipeline.send(:extractor)
        pipeline.send(:transformers)
        pipeline.send(:loader)
      end
    end

    context 'when options are missing' do
      before do
        klass = Class.new do
          include BulkImports::Pipeline

          extractor BulkImports::Extractor
          transformer BulkImports::Transformer
          loader BulkImports::Loader
        end

        stub_const('BulkImports::NoOptionsPipeline', klass)
      end

      it 'instantiates new object without options' do
        expect(BulkImports::Extractor).to receive(:new).with(no_args)
        expect(BulkImports::Transformer).to receive(:new).with(no_args)
        expect(BulkImports::Loader).to receive(:new).with(no_args)

        pipeline = BulkImports::NoOptionsPipeline.new(context)

        pipeline.send(:extractor)
        pipeline.send(:transformers)
        pipeline.send(:loader)
      end
    end
  end

  describe '#transformers' do
    before do
      klass = Class.new do
        include BulkImports::Pipeline

        transformer BulkImports::Transformer

        def transform; end
      end

      stub_const('BulkImports::TransformersPipeline', klass)
    end

    it 'has instance transform method first to run' do
      transformer = double
      allow(BulkImports::Transformer).to receive(:new).and_return(transformer)

      pipeline = BulkImports::TransformersPipeline.new(context)

      expect(pipeline.send(:transformers)).to eq([pipeline, transformer])
    end
  end
end
