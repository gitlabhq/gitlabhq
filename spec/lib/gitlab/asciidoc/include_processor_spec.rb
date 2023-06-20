# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe Gitlab::Asciidoc::IncludeProcessor do
  let_it_be(:project) { create(:project, :repository) }

  let(:processor_context) do
    {
      project: project,
      max_includes: max_includes,
      ref: ref
    }
  end

  let(:ref) { project.repository.root_ref }
  let(:max_includes) { 10 }

  let(:reader) { Asciidoctor::PreprocessorReader.new(document, lines, 'file.adoc') }

  let(:document) { Asciidoctor::Document.new(lines) }

  subject(:processor) { described_class.new(processor_context) }

  let(:a_blob) { double(:Blob, readable_text?: true, data: a_data) }
  let(:a_data) { 'include::b.adoc[]' }

  let(:directives) { [':max-include-depth: 1000'] }
  let(:lines) { directives + Array.new(10, 'include::a.adoc[]') }

  before do
    allow(project.repository).to receive(:blob_at).with(ref, anything).and_return(nil)
    allow(project.repository).to receive(:blob_at).with(ref, 'a.adoc').and_return(a_blob)
  end

  describe 'read_lines' do
    let(:result) { processor.send(:read_lines, filename, selector) }
    let(:selector) { nil }

    context 'when reading a file in the repository' do
      let(:filename) { 'a.adoc' }

      it 'returns the blob contents' do
        expect(result).to match_array([a_data])
      end

      context 'when the blob does not exist' do
        let(:filename) { 'this-file-does-not-exist' }

        it 'raises NoData' do
          expect { result }.to raise_error(described_class::NoData)
        end
      end

      context 'when there is a selector' do
        let(:a_data) { %w[a b c d].join("\n") }
        let(:selector) { ->(_, lineno) { lineno.odd? } }

        it 'selects the lines' do
          expect(result).to eq %W[a\n c\n]
        end
      end

      it 'allows at most N blob includes' do
        max_includes.times do
          processor.send(:read_lines, filename, selector)
        end

        expect(processor.send(:include_allowed?, 'anything', reader)).to be_falsey
      end
    end

    context 'when reading content from a URL' do
      let(:filename) { 'http://example.org/file' }

      it 'fetches the data using a GET request' do
        stub_request(:get, filename).to_return(status: 200, body: 'something')

        expect(result).to match_array(['something'])
      end

      context 'when the URI returns 404' do
        before do
          stub_request(:get, filename).to_return(status: 404, body: 'not found')
        end

        it 'raises NoData' do
          expect { result }.to raise_error(described_class::NoData)
        end
      end

      it 'allows at most N HTTP includes' do
        stub_request(:get, filename).to_return(status: 200, body: 'something')

        max_includes.times do
          processor.send(:read_lines, filename, selector)
        end

        expect(processor.send(:include_allowed?, 'anything', reader)).to be_falsey
      end

      context 'when there is a selector' do
        let(:http_body) { %w[x y z].join("\n") }
        let(:selector) { ->(_, lineno) { lineno.odd? } }

        it 'selects the lines' do
          stub_request(:get, filename).to_return(status: 200, body: http_body)

          expect(result).to eq %W[x\n z]
        end
      end
    end
  end

  describe '#include_allowed?' do
    context 'when allow-uri-read is nil' do
      before do
        allow(document).to receive(:attributes).and_return({ 'max-include-depth' => 100, 'allow-uri-read' => nil })
      end

      it 'allows http includes' do
        expect(processor.send(:include_allowed?, 'http://example.com', reader)).to be_falsey
        expect(processor.send(:include_allowed?, 'https://example.com', reader)).to be_falsey
      end

      it 'allows blob includes' do
        expect(processor.send(:include_allowed?, 'a.blob', reader)).to be_truthy
      end
    end

    context 'when allow-uri-read is false' do
      before do
        allow(document).to receive(:attributes).and_return({ 'max-include-depth' => 100, 'allow-uri-read' => false })
      end

      it 'allows http includes' do
        expect(processor.send(:include_allowed?, 'http://example.com', reader)).to be_falsey
        expect(processor.send(:include_allowed?, 'https://example.com', reader)).to be_falsey
      end

      it 'allows blob includes' do
        expect(processor.send(:include_allowed?, 'a.blob', reader)).to be_truthy
      end
    end

    context 'when allow-uri-read is true' do
      before do
        allow(document).to receive(:attributes).and_return({ 'max-include-depth' => 100, 'allow-uri-read' => true })
      end

      it 'allows http includes' do
        expect(processor.send(:include_allowed?, 'http://example.com', reader)).to be_truthy
        expect(processor.send(:include_allowed?, 'https://example.com', reader)).to be_truthy
      end

      it 'allows blob includes' do
        expect(processor.send(:include_allowed?, 'a.blob', reader)).to be_truthy
      end
    end

    context 'without allow-uri-read' do
      before do
        allow(document).to receive(:attributes).and_return({ 'max-include-depth' => 100 })
      end

      it 'forbids http includes' do
        expect(processor.send(:include_allowed?, 'http://example.com', reader)).to be_falsey
        expect(processor.send(:include_allowed?, 'https://example.com', reader)).to be_falsey
      end

      it 'allows blob includes' do
        expect(processor.send(:include_allowed?, 'a.blob', reader)).to be_truthy
      end
    end

    it 'allows the first include' do
      expect(processor.send(:include_allowed?, 'foo.adoc', reader)).to be_truthy
    end

    it 'allows the Nth include' do
      (max_includes - 1).times { processor.send(:read_lines, 'a.adoc', nil) }

      expect(processor.send(:include_allowed?, 'foo.adoc', reader)).to be_truthy
    end

    it 'disallows the Nth + 1 include' do
      max_includes.times { processor.send(:read_lines, 'a.adoc', nil) }

      expect(processor.send(:include_allowed?, 'foo.adoc', reader)).to be_falsey
    end
  end
end
