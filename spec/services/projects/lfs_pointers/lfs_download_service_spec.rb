require 'spec_helper'

describe Projects::LfsPointers::LfsDownloadService do
  let(:project) { create(:project) }
  let(:oid) { '9e548e25631dd9ce6b43afd6359ab76da2819d6a5b474e66118c7819e1d8b3e8' }
  let(:download_link) { "http://gitlab.com/#{oid}" }
  let(:lfs_content) do
    <<~HEREDOC
    whatever
    HEREDOC
  end

  subject { described_class.new(project) }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(true)
    WebMock.stub_request(:get, download_link).to_return(body: lfs_content)
  end

  describe '#execute' do
    context 'when file download succeeds' do
      it 'a new lfs object is created' do
        expect { subject.execute(oid, download_link) }.to change { LfsObject.count }.from(0).to(1)
      end

      it 'has the same oid' do
        subject.execute(oid, download_link)

        expect(LfsObject.first.oid).to eq oid
      end

      it 'stores the content' do
        subject.execute(oid, download_link)

        expect(File.read(LfsObject.first.file.file.file)).to eq lfs_content
      end
    end

    context 'when file download fails' do
      it 'no lfs object is created' do
        expect { subject.execute(oid, download_link) }.to change { LfsObject.count }
      end
    end

    context 'when credentials present' do
      let(:download_link_with_credentials) { "http://user:password@gitlab.com/#{oid}" }

      before do
        WebMock.stub_request(:get, download_link).with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNzd29yZA==' }).to_return(body: lfs_content)
      end

      it 'the request adds authorization headers' do
        subject.execute(oid, download_link_with_credentials)
      end
    end

    context 'when an lfs object with the same oid already exists'  do
      before do
        create(:lfs_object, oid: 'oid')
      end

      it 'does not download the file' do
        expect(subject).not_to receive(:download_and_save_file)

        subject.execute('oid', download_link)
      end
    end
  end
end
