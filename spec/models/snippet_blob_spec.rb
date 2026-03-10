# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetBlob do
  let(:snippet) { create(:project_snippet) }

  subject { described_class.new(snippet) }

  describe '#id' do
    it 'returns the snippet ID' do
      expect(subject.id).to eq(snippet.id)
    end
  end

  describe '#name' do
    it 'returns the snippet file name' do
      expect(subject.name).to eq(snippet.file_name)
    end
  end

  describe '#size' do
    it 'returns the data size' do
      expect(subject.size).to eq(subject.data.bytesize)
    end
  end

  describe '#data' do
    it 'returns the snippet content' do
      expect(subject.data).to eq(snippet.content)
    end
  end
end
