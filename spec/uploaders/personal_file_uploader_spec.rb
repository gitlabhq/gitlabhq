require 'spec_helper'

IDENTIFIER = %r{\h+/\S+}

describe PersonalFileUploader do
  let(:model) { create(:personal_snippet) }
  let(:uploader) { described_class.new(model) }
  let(:upload) { create(:upload, :personal_snippet_upload) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/personal_snippet/\d+],
                  upload_path: IDENTIFIER,
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/personal_snippet/\d+/#{IDENTIFIER}]

  describe '#to_h' do
    before do
      subject.instance_variable_set(:@secret, 'secret')
    end

    it 'is correct' do
      allow(uploader).to receive(:file).and_return(double(extension: 'txt', filename: 'file_name'))
      expected_url = "/uploads/-/system/personal_snippet/#{model.id}/secret/file_name"

      expect(uploader.to_h).to eq(
        alt: 'file_name',
        url: expected_url,
        markdown: "[file_name](#{expected_url})"
      )
    end
  end
end
