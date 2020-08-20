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
  let(:a_data) { StringIO.new('include::b.adoc[]') }

  let(:lines) { [':max-include-depth: 1000'] + Array.new(10, 'include::a.adoc[]') }

  before do
    allow(project.repository).to receive(:blob_at).with(ref, 'a.adoc').and_return(a_blob)
  end

  describe '#include_allowed?' do
    it 'allows the first include' do
      expect(processor.send(:include_allowed?, 'foo.adoc', reader)).to be_truthy
    end

    it 'allows the Nth include' do
      (max_includes - 1).times { processor.send(:read_blob, ref, 'a.adoc') }

      expect(processor.send(:include_allowed?, 'foo.adoc', reader)).to be_truthy
    end

    it 'disallows the Nth + 1 include' do
      max_includes.times { processor.send(:read_blob, ref, 'a.adoc') }

      expect(processor.send(:include_allowed?, 'foo.adoc', reader)).to be_falsey
    end
  end
end
