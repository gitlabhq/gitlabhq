require 'spec_helper'

describe PersonalFileUploader do
  let(:model) { create(:personal_snippet) }
  let(:uploader) { described_class.new(model) }
  let(:upload) { create(:upload, :personal_snippet_upload) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/personal_snippet/\d+],
                  upload_path: %r[\h+/\S+],
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/personal_snippet\/\d+\/\h+\/\S+$]

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[\d+/\h+],
                    upload_path: %r[^personal_snippet\/\d+\/\h+\/<filename>]
  end

  describe '#upload_paths' do
    it 'builds correct paths for both local and remote storage' do
      paths = uploader.upload_paths('test.jpg')

      expect(paths.first).to match(%r[\h+\/test.jpg])
      expect(paths.second).to match(%r[^personal_snippet\/\d+\/\h+\/test.jpg])
    end
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
      uploader.store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end
end
