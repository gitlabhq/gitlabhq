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

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[\d+/\h+],
                    upload_path: IDENTIFIER
  end

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

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload(Rails.root.join('spec/fixtures/doc_sample.txt')))
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end
end
