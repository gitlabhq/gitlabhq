require 'spec_helper'

describe PersonalFileUploader do
  let(:uploader) { described_class.new(build_stubbed(:empty_project)) }
  let(:snippet) { create(:personal_snippet) }

  describe '.absolute_path' do
    it 'returns the correct absolute path by building it dynamically' do
      upload = double(model: snippet, path: 'secret/foo.jpg')

      dynamic_segment = "personal_snippet/#{snippet.id}"

      expect(described_class.absolute_path(upload)).to end_with("/system/#{dynamic_segment}/secret/foo.jpg")
    end
  end

  describe '#to_h' do
    it 'returns the hass' do
      uploader = described_class.new(snippet, 'secret')

      allow(uploader).to receive(:file).and_return(double(extension: 'txt', filename: 'file_name'))
      expected_url = "/uploads/system/personal_snippet/#{snippet.id}/secret/file_name"

      expect(uploader.to_h).to eq(
        alt: 'file_name',
        url: expected_url,
        markdown: "[file_name](#{expected_url})"
      )
    end
  end
end
