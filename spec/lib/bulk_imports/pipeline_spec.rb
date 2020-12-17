# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline do
  describe 'pipeline attributes' do
    before do
      stub_const('BulkImports::Extractor', Class.new)
      stub_const('BulkImports::Transformer', Class.new)
      stub_const('BulkImports::Loader', Class.new)

      klass = Class.new do
        include BulkImports::Pipeline

        abort_on_failure!

        extractor BulkImports::Extractor, { foo: :bar }
        transformer BulkImports::Transformer, { foo: :bar }
        loader BulkImports::Loader, { foo: :bar }
      end

      stub_const('BulkImports::MyPipeline', klass)
    end

    describe 'getters' do
      it 'retrieves class attributes' do
        expect(BulkImports::MyPipeline.extractors).to contain_exactly({ klass: BulkImports::Extractor, options: { foo: :bar } })
        expect(BulkImports::MyPipeline.transformers).to contain_exactly({ klass: BulkImports::Transformer, options: { foo: :bar } })
        expect(BulkImports::MyPipeline.loaders).to contain_exactly({ klass: BulkImports::Loader, options: { foo: :bar } })
        expect(BulkImports::MyPipeline.abort_on_failure?).to eq(true)
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

        expect(BulkImports::MyPipeline.extractors)
          .to contain_exactly(
            { klass: BulkImports::Extractor, options: { foo: :bar } },
            { klass: klass, options: options })

        expect(BulkImports::MyPipeline.transformers)
          .to contain_exactly(
            { klass: BulkImports::Transformer, options: { foo: :bar } },
            { klass: klass, options: options })

        expect(BulkImports::MyPipeline.loaders)
          .to contain_exactly(
            { klass: BulkImports::Loader, options: { foo: :bar } },
            { klass: klass, options: options })

        expect(BulkImports::MyPipeline.abort_on_failure?).to eq(true)
      end
    end
  end
end
