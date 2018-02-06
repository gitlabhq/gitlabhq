require 'spec_helper'

describe SnippetBlob do
  let(:snippet) { create(:snippet) }

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

  describe '#rendered_markup' do
    context 'when the content is GFM' do
      let(:snippet) { create(:snippet, file_name: 'file.md') }

      it 'returns the rendered GFM' do
        expect(subject.rendered_markup).to eq(snippet.content_html)
      end
    end

    context 'when the content is not GFM' do
      it 'returns nil' do
        expect(subject.rendered_markup).to be_nil
      end
    end
  end
end
