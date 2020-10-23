# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Pipeline::Runner do
  describe 'pipeline runner' do
    before do
      extractor = Class.new do
        def initialize(options = {}); end

        def extract(context); end
      end

      transformer = Class.new do
        def initialize(options = {}); end

        def transform(context, entry); end
      end

      loader = Class.new do
        def initialize(options = {}); end

        def load(context, entry); end
      end

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

    it 'runs pipeline extractor, transformer, loader' do
      context = instance_double(BulkImports::Pipeline::Context)
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

      BulkImports::MyPipeline.new.run(context)
    end
  end
end
